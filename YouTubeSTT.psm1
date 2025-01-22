#!/usr/bin/env pwsh
using namespace System.IO
using namespace System.Management.Automation

#Requires -Modules cliHelper.core, pipEnv
#Requires -Psedition Core


#region    Classes
enum SttOutFormat {
  PSObject
  Markdown
}



# .SYNOPSIS
#   A short one-line action-based description, e.g. 'Tests if a function is valid'
# .EXAMPLE
#   [YouTubeSTT]::GetTranscript("https://youtu.be/t9b0YBDd0Ho")
class YouTubeSTT {
  static [hashtable]$status = [hashtable]::Synchronized(@{
      HasConfig = [YouTubeSTT]::HasConfig()
    }
  )
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
    $vidId = [YouTubeSTT]::GetvideoId($videoId);
    $langOptLinks = [YouTubeSTT]::GetLangOptionsWithLink($vidId); $has_transcript_link = !($langOptLinks.Count -eq 0 -or $null -eq $langOptLinks[0].link)
    if ($has_transcript_link) {
      $link = $langOptLinks[0].link
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
    }
    # Offline transcribe
    [void][YouTubeSTT]::ResolveRequirements(); $_c = [YouTubeSTT].config; $tmpfile = [IO.Path]::GetTempFileName()
    $_t = [IO.Path]::Combine(($_c.backgroundScript | Split-Path), "transcribe.py"); $dir = $_c.workingDirectory
    $Process = Start-Process -FilePath "python" -ArgumentList "$_t --video_id `"$vidId`" --outfile `"$tmpfile`" --working-directory `"$dir`"" -WorkingDirectory $dir -PassThru -NoNewWindow;
    $Process.WaitForExit(); $process.Kill(); $Process.Dispose()
    $res = [IO.File]::ReadAllText($tmpfile); [IO.File]::Delete($tmpfile)
    return $res
  }
  static [string] GetVideoPageHtml([string]$videoId) {
    try {
      $response = Invoke-WebRequest -Uri "https://www.youtube.com/watch?v=$videoId" -Verbose:$false
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
  static [bool] ResolveRequirements() {
    $_c = [YouTubeSTT].config; $req = $_c.requirementsfile; $res = [IO.File]::Exists($req);
    if (!$res) { throw "YouTubeSTT failed to resolve pip requirements. From file: '$req'." }
    Write-Console "Found file @$(Invoke-PathShortener $req)" -f LemonChiffon;
    if (![YouTubeSTT]::status.HasConfig) { throw [InvalidOperationException]::new("YouTubeSTT config found.") };
    if ($_c.env.State -eq "Inactive") { $_c.env.Activate() }
    Write-Console "(YouTubeSTT) " -f SlateBlue -NoNewLine; Write-Console "၊▹ Resolve pip requirements ... " -f LemonChiffon -NoNewLine -Animate
    pip install -r $req
    Write-Console "Done" -f LimeGreen
    return $res
  }
  static [bool] HasConfig() {
    if ($null -eq [YouTubeSTT].config) { [YouTubeSTT].PsObject.Properties.Add([PSScriptproperty]::New("config", { return [YouTubeSTT]::LoadConfig() }, { throw [SetValueException]::new("config can only be imported or edited") })) }
    return $null -ne [YouTubeSTT].config
  }
  static [PsObject] LoadConfig() {
    return [YouTubeSTT]::LoadConfig((Resolve-Path .).Path)
  }
  static [PsObject] LoadConfig([string]$current_path) {
    # .DESCRIPTION
    #   Load the configuration from json or toml file
    $module_path = (Get-Module YouTubeSTT -ListAvailable -Verbose:$false).ModuleBase
    # default config values
    $c = @{
      workingDirectory = $current_path
      requirementsfile = [IO.Path]::Combine($module_path, "Private", "requirements.txt")
      backgroundScript = [IO.Path]::Combine($module_path, "Private", "transcribe.py")
      outFile          = [IO.Path]::Combine($current_path, "$(Get-Date -Format 'yyyyMMddHHmmss')_output.json")
    } -as "PsRecord"
    $c.PsObject.Properties.Add([PSScriptproperty]::New("env", { return [YouTubeSTT].config.workingDirectory | New-pipEnv }, { throw [SetValueException]::new("env is read-only") }))
    $c.PsObject.Properties.Add([PSScriptproperty]::New("modulePath", [scriptblock]::Create("return `"$module_path`""), { throw [SetValueException]::new("modulePath is read-only") }))
    return $c
  }
  static [string] GetRawTranscript([string]$link) {
    if (!$link.StartsWith('https://www.youtube.com')) {
      $uri = ('https://www.youtube.com{0}' -f $link)
    } else {
      $uri = $link
    }
    $transcriptPageResponse = Invoke-WebRequest -Uri $uri -Verbose:$false
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
