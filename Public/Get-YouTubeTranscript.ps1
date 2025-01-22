function Get-YouTubeTranscript {
  # .SYNOPSIS
  #   Get the transcript of a YouTube video
  # .DESCRIPTION
  #   Get the transcript of a YouTube video
  # .LINK
  #   https://github.com/alainQtec/YouTubeSTT/blob/main/Public/Get-YouTubeTranscript.ps1
  # .EXAMPLE
  #   Get-YouTubeTranscript https://www.youtube.com/watch?v=t9b0YBDd0Ho -o transcript.json
  [CmdletBinding()][OutputType([string])]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({
        if (!($_ -match '^https?:\/\/(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)$')) {
          throw [System.ArgumentException]::New('Please Provide a valid YouTube URL')
        }
        return $true
      })
    ][Alias('u')]
    [string]$Url,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateNotNullOrWhiteSpace()][Alias('o')]
    [string]$OutFile
  )

  process {
    $t = [YouTubeSTT]::GetTranscript($Url)
    if ($PSBoundParameters.ContainsKey("Outfile")) {
      $t | Out-File -FilePath $OutFile
    }
  }

  end {
    return $t
  }
}