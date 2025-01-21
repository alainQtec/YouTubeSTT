# [YouTubeSTT](https://www.powershellgallery.com/packages/YouTubeSTT)

A PowerShell module designed to help you transcribe and extract meaningful data
from YouTube videos directly in your terminal.

## Features

- Transcribe YouTube videos quickly.
- Extract timestamps, key insights, notable quotes, and more.
- Fully customizable output options.

## Installation

To install the YouTubeSTT module, run:

```powershell
Install-Module YouTubeSTT
```

## Getting Started

After installation, import the module into your PowerShell session:

```powershell
Import-Module YouTubeSTT
```

### Usage

```powershell
# Transcribe a YouTube video and save the transcript to a file
Get-YouTubeTranscript -Url "https://www.youtube.com/watch?v=dQw4w9WgXcQ" -OutputFile "transcript.txt"

# Extract key insights from a video
Get-YouTubeInsights -Url "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

## Contributing

Contributions are welcome!

## License

This project is licensed under the [WTFPL License](LICENSE).
