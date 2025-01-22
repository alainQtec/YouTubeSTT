function Get-YouTubeTranscript {
  # .SYNOPSIS
  #   Get the transcript of a YouTube video
  # .DESCRIPTION
  #   Get the transcript of a YouTube video
  # .NOTES
  #   Information or caveats about the function e.g. 'This function is not supported in Linux'
  # .LINK
  #   https://github.com/alainQtec/YouTubeSTT/blob/main/Public/Get-YouTubeTranscript.ps1
  # .EXAMPLE
  #   Get-YouTubeTranscript https://www.youtube.com/watch?v=t9b0YBDd0Ho -o transcript.json
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({
        if (Test-YouTubeUrl -Url $_) {
          return $true
        } else {
          throw [System.ArgumentException]::New('Please Provide a valid YouTube URL')
        }
      })
    ][Alias('u')]
    [string]$Url,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateNotNullOrWhiteSpace()][Alias('o')]
    [string]$OutFile
  )

  begin {
  }

  process {
  }

  end {
  }
}