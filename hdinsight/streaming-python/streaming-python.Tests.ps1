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
$mapper= @"
#!/usr/bin/env python

# Use the sys module
import sys

# 'file' in this case is STDIN
def read_input(file):
    # Split each line into words
    for line in file:
        yield line.split()

def main(separator='\t'):
    # Read the data using read_input
    data = read_input(sys.stdin)
    # Process each words returned from read_input
    for words in data:
        # Process each word
        for word in words:
            # Write to STDOUT
            print '%s%s%d' % (word, separator, 1)

if __name__ == "__main__":
    main()
"@
$reducer=@"
#!/usr/bin/env python

# import modules
from itertools import groupby
from operator import itemgetter
import sys

# 'file' in this case is STDIN
def read_mapper_output(file, separator='\t'):
    # Go through each line
    for line in file:
        # Strip out the separator character
        yield line.rstrip().split(separator, 1)

def main(separator='\t'):
    # Read the data using read_mapper_output
    data = read_mapper_output(sys.stdin, separator=separator)
    # Group words and counts into 'group'
    #   Since MapReduce is a distributed process, each word
    #   may have multiple counts. 'group' will have all counts
    #   which can be retrieved using the word as the key.
    for current_word, group in groupby(data, itemgetter(0)):
        try:
            # For each word, pull the count(s) for the word
            #   from 'group' and create a total count
            total_count = sum(int(count) for current_word, count in group)
            # Write to stdout
            print "%s%s%d" % (current_word, separator, total_count)
        except ValueError:
            # Count was not a number, so do nothing
            pass

if __name__ == "__main__":
    main()
"@

Describe "streaming-python" {
    # Use testdrive since there is a downloaded file
    in $TestDrive {
        # Store the scripts so they can be uploaded during tests
        $mapper | Out-File .\mapper.py
        $reducer | Out-File .\reducer.py
        # Mock the cluster name prompt
        Mock Read-Host { $clusterName }
        # Mock Write-Progress to keep from clobbering test progress indicator
        Mock Write-Progress { }

        It "Converts CRLF line endings to just LF" {
            # Use $TestDrive:\file format since the function uses .NET objects
            {Fix-LineEnding("$TestDrive\mapper.py")} | Should not throw
            {Fix-LineEnding("$TestDrive\reducer.py")} | Should not throw
            '.\mapper.py' | Should not Contain "`r`n"
            '.\reducer.py' | Should not Contain "`r`n"
        }

        It "Uploads the python files and runs the job" {
            # Test the script
            # NOTE: There's no great test to validate the return data
            # because it is returned differently depending on whether you use
            # a blob or data lake store with HDInsight.
            {Start-PythonExample} |  Should not throw
        }
    }
}
