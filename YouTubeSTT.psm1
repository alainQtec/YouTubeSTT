#!/usr/bin/env pwsh

#region    Classes
enum SttOutFormat {
  PSObject
  Markdown
}

class YouTubeSTT {
  static [string] $Summary_instructions
  static [string] GetvideoId([string]$InputString) {
    $pattern = '(?:https?:\/\/)?(?:www\.)?(?:youtube\.com|youtu\.be)\/(?:watch\?v=)?(?:embed\/)?(?:v\/)?(?:shorts\/)?(?:\S*[^\w\-\s])?(?<id>[\w\-]{11})(?:\S*)?'
    if ($InputString -match $pattern) {
      $videoId = $matches['id']
      return $videoId
    } elseif ($InputString -match '^[\w\-]{11}$') {
      return $InputString
    } else {
      throw [System.ArgumentException]::New('No valid YouTube video ID found in the string.')
    }
  }
  static [string] GetTranscript([string]$videoId) {
    return [YouTubeSTT]::GetTranscript($videoId, $true)
  }
  static [string] GetTranscript([string]$videoId, [bool]$IncludeTitle) {
    return [YouTubeSTT]::GetTranscript($videoId, $IncludeTitle, [SttOutFormat]::PSObject)
  }
  static [string] GetTranscript([string]$videoId, [bool]$IncludeTitle, [SttOutFormat]$OutputFormat) {
    return [YouTubeSTT]::GetTranscript($videoId, $IncludeTitle, $OutputFormat, $false)
  }
  static [string] GetTranscript([string]$videoId, [bool]$IncludeTitle, [SttOutFormat]$OutputFormat, [bool]$IncludeDescription) {
    $vidId = [YouTubeSTT]::GetvideoId($videoId)
    $langOptLinks = [YouTubeSTT]::GetLangOptionsWithLink($vidId)
    if ($langOptLinks.Count -eq 0) {
      Write-Host 'No transcripts available for this video.'
      return $null
    }

    $link = $langOptLinks[0].link
    if ($null -ne $link) {
      # return the video info
      # title, description, transcript
      $markdown = "# Video Transcript`n"
      $videoinfo = [PSCustomObject][ordered]@{
      }
      if ($IncludeTitle) {
        $videoinfo | Add-Member -NotePropertyName 'title' -NotePropertyValue $langOptLinks[0].title
        $markdown += "## Title`n$($langOptLinks[0].title)`n"
      }
      if ($IncludeDescription) {
        $videoinfo | Add-Member -NotePropertyName 'description' -NotePropertyValue $langOptLinks[0].description
        $markdown += "## Description`n$($langOptLinks[0].description)`n"
      }
      $videoinfo | Add-Member -NotePropertyName 'language' -NotePropertyValue $langOptLinks[0].language
      $markdown += "## Language`n$($langOptLinks[0].language)`n"
      $videoinfo | Add-Member -NotePropertyName 'transcript' -NotePropertyValue ([YouTubeSTT]::GetRawTranscript($link))
      $markdown += @"
## Transcript
| Start    | Duration | Text |
| :------- | :------ | :------ |`n
"@
      foreach ($part in $videoinfo.transcript) {
        $markdown += "| $($part.start) | $($part.duration) | $($part.text) |`n"
      }
      if ($OutputFormat -eq 'Markdown') {
        return $markdown
      } else {
        return $videoinfo
      }
    } else {
      Write-Host 'No valid link found for the transcript.'
      return $null
    }
  }
  static [string] GetVideoPageHtml([string]$videoId) {
    try {
      $response = Invoke-WebRequest -Uri "https://www.youtube.com/watch?v=$videoId"
      $html = $response.Content
      # Check if the HTML content contains the video URL: <meta property="og:url" content="https://www.youtube.com/watch?v=GikIJpUv6oo">
      if ($html -match 'og:url') {
        # Check if the HTML content contains 'class="g-recaptcha"'
        if ($html -match 'class="g-recaptcha"') {
          Write-Host "Failed to get the HTML content Too Many Requests for video ID: $videoId"
          return $null
        }
        # Check if the HTML content contains '"playabilityStatus":'
        if ($html -notmatch '"playabilityStatus":') {
          Write-Host "Failed to get the HTML content Video Unavailable for video ID: $videoId"
          return $null
        }
        return $html
      } else {
        Write-Host "Failed to get the HTML content for video ID: $videoId"
        return $null
      }
    } catch {
      Write-Host "Failed to get the HTML content for video ID: $videoId"
      return $null
    }
  }
  static [string[]] GetLangOptionsWithLink([string]$videoId) {
    $videoPageHtml = [YouTubeSTT]::GetVideoPageHtml($videoId)
    if (!$videoPageHtml) {
      Write-Host 'Failed to get video page HTML'
      return @()
    }
    $splittedHtml = $videoPageHtml -split '"captions":'
    if ($splittedHtml.Length -lt 2) {
      Write-Host 'No Caption Available'
      return @() # No Caption Available
    }

    try {
      $JsonregexPattern = '{(?:[^{}]|(?<Open>{)|(?<-Open>}))*(?(Open)(?!))}'
      $captionsJson = $splittedHtml[1] -split ',"videoDetails' | Select-Object -First 1
      $videoDetailsJson = ([regex]::Match(($splittedHtml[1] -split ',"videoDetails')[1], $JsonregexPattern).Value | ConvertFrom-Json)
      $captions = ConvertFrom-Json $captionsJson
      # Extract the caption tracks: baseUrl=/api/timedtext?...... this url does expire after some time
      $captionTracks = $captions.playerCaptionsTracklistRenderer.captionTracks
      # This will give the language options
      # if $_.name.runs.text else $_.name.simpleText

      $languageOptions = $captionTracks | ForEach-Object {
        if ($_.name.runs.text) {
          $_.name.runs.text
        } else {
          $_.name.simpleText
        } }

      # Looks like most will be 'English (auto-generated)' and 'English' azurming this is manuly created, so the one we want over auto-generated
      $languageOptions = $languageOptions | Sort-Object {
        if ($_ -eq 'English') {
          return -1
        } elseif ($_ -match 'English') {
          return 0
        } else {
          return 1
        }
      }

      $languageOptionsWithLink = $languageOptions | ForEach-Object {
        $langName = $_
        # $link = ($captionTracks | Where-Object { $_.name.runs[0].text -or $_.name.simpleText -eq $langName }).baseUrl
        $link = $captionTracks | ForEach-Object {
          $name = if ($_.name.runs) { $_.name.runs[0].text } else { $_.name.simpleText }
          if ($name -eq $langName) { $_.baseUrl }
        } | Select-Object -First 1
        [PSCustomObject]@{
          title       = $videoDetailsJson.title
          description = $videoDetailsJson.shortDescription
          language    = $langName
          link        = $link
        }
      }

      return $languageOptionsWithLink
    } catch {
      Write-Host 'Error parsing captions JSON'
      return $null
    }
  }
  static [string] GetRawTranscript([string]$link) {
    if (!$link.StartsWith('https://www.youtube.com')) {
      $uri = ('https://www.youtube.com{0}' -f $link)
    } else {
      $uri = $link
    }
    $transcriptPageResponse = Invoke-WebRequest -Uri $uri
    [xml]$xmlDoc = [xml](New-Object System.Xml.XmlDocument)
    $xmlDoc.LoadXml($transcriptPageResponse.Content)
    $textNodes = $xmlDoc.documentElement.ChildNodes
    $transcriptParts = @()
    foreach ($node in $textNodes) {
      $transcriptParts += [PSCustomObject]@{
        start    = $node.GetAttribute('start')
        duration = $node.GetAttribute('dur')
        text     = [System.Web.HttpUtility]::HtmlDecode($node.InnerText)
      }
    }
    return $transcriptParts
  }
}
#endregion Classes

# Types that will be available to users when they import the module.
$typestoExport = @(
  [YouTubeSTT]
)
$TypeAcceleratorsClass = [PsObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
foreach ($Type in $typestoExport) {
  if ($Type.FullName -in $TypeAcceleratorsClass::Get.Keys) {
    $Message = @(
      "Unable to register type accelerator '$($Type.FullName)'"
      'Accelerator already exists.'
    ) -join ' - '

    [System.Management.Automation.ErrorRecord]::new(
      [System.InvalidOperationException]::new($Message),
      'TypeAcceleratorAlreadyExists',
      [System.Management.Automation.ErrorCategory]::InvalidOperation,
      $Type.FullName
    ) | Write-Warning
  }
}
# Add type accelerators for every exportable type.
foreach ($Type in $typestoExport) {
  $TypeAcceleratorsClass::Add($Type.FullName, $Type)
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  foreach ($Type in $typestoExport) {
    $TypeAcceleratorsClass::Remove($Type.FullName)
  }
}.GetNewClosure();

$scripts = @();
$Public = Get-ChildItem "$PSScriptRoot/Public" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
$scripts += Get-ChildItem "$PSScriptRoot/Private" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
$scripts += $Public

foreach ($file in $scripts) {
  Try {
    if ([string]::IsNullOrWhiteSpace($file.fullname)) { continue }
    . "$($file.fullname)"
  } Catch {
    Write-Warning "Failed to import function $($file.BaseName): $_"
    $host.UI.WriteErrorLine($_)
  }
}

$Param = @{
  Function = $Public.BaseName
  Cmdlet   = '*'
  Alias    = '*'
  Verbose  = $false
}
Export-ModuleMember @Param
