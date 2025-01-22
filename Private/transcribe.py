import argparse
from doctest import Example
import os
import time
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api.formatters import TextFormatter
from youtube_transcript_api._errors import NoTranscriptFound, VideoUnavailable

# Example:
# python Private/transcribe.py --video_id dQw4w9WgXcQ

# --- Argument Parsing ---
parser = argparse.ArgumentParser(description='Audio transcription with Socket Output')
parser.add_argument('--outfile', type=str, default=time.strftime("%Y%m%d-%H%M%S") + "_output.txt", help='Output file for the transcript')
parser.add_argument('--working-directory', type=str, default=os.getcwd(), help='Working directory for the script')
parser.add_argument('--video_id', type=str, help='ID of the YouTube video')
args = parser.parse_args()

# --- Main ---
def main():
    if not args.video_id:
        print("Please provide a video ID using the --video_id argument.")
        return

    try:
        transcript = YouTubeTranscriptApi.get_transcript(args.video_id)
        formatter = TextFormatter()
        formatted_transcript = formatter.format_transcript(transcript)

        with open(args.outfile, 'w', encoding='utf-8') as outfile:
            outfile.write(formatted_transcript)

        print(f"Transcript written to {args.outfile}")

    except VideoUnavailable:
        print(f"Error: Video with ID '{args.video_id}' is unavailable.")
    except NoTranscriptFound:
        print(f"Error: No transcript found for video with ID '{args.video_id}'.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
