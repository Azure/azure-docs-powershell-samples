$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword


# Mocks don't work for Get-Credential, so we're implementing our own version of it. This is used for tests instead of the real one.
function Get-Credential { return $creds }

# declare the scripts here, since we don't want to pull from another repo or clutter this one.
$streamingpy= @"
#!/usr/bin/env python
import sys
import string
import hashlib

while True:
    line = sys.stdin.readline()
    if not line:
        break

    line = string.strip(line, "\n ")
    clientid, devicemake, devicemodel = string.split(line, "\t")
    phone_label = devicemake + ' ' + devicemodel
    print "\t".join([clientid, phone_label, hashlib.md5(phone_label).hexdigest()])
"@
$pigpython=@"
# Uncomment the following if using C Python
#from pig_util import outputSchema

@outputSchema("log: {(date:chararray, time:chararray, classname:chararray, level:chararray, detail:chararray)}")
def create_structure(input):
    if (input.startswith('java.lang.Exception')):
        input = input[21:len(input)] + ' - java.lang.Exception'
    date, time, classname, level, detail = input.split(' ', 4)
    return date, time, classname, level, detail
"@

Describe "hdinsight-python" {
    # Use testdrive since there is a downloaded file
    in $TestDrive {
        # Store the scripts so they can be uploaded during tests
        $streamingpy | Out-File .\streaming.py
        $pigpython | Out-File .\pig_python.py
        # Mock the cluster name prompt
        Mock Read-Host { $clusterName }
        # Mock Write-Progress to keep from clobbering test progress indicator
        Mock Write-Progress { }

        It "Converts CRLF line endings to just LF" {
            # Use $TestDrive:\file format since the function uses .NET objects
            {Fix-LineEnding("$TestDrive\streaming.py")} | Should not throw
            {Fix-LineEnding("$TestDrive\pig_python.py")} | Should not throw
            '.\streaming.py' | Should not Contain "`r`n"
            '.\pig_python.py' | Should not Contain "`r`n"
        }

        It "Uploads the python files to Az.Storage" {
            # Test that the job succeeded
            { Add-PythonFiles } | Should not throw
        }
        It "Runs the hive job" {
            # Test the return data
            (Start-HiveJob)[-1].Contains("100004") | Should be True
        }
        It "Runs the pig job" {
            # Test the return data
            (Start-PigJob)[-1].StartsWith("((2012-02-03") | Should be True
        }
    }
}
