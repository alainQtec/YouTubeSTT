import os
import time
import argparse
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api.formatters import TextFormatter
from youtube_transcript_api._errors import NoTranscriptFound, VideoUnavailable

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
        json_formatted = formatter.format_transcript(transcript, indent=2)
        with open(args.outfile, 'w', encoding='utf-8') as outfile:
            outfile.write(json_formatted)

        # print(f"Transcript written to {args.outfile}")

    except VideoUnavailable:
        print(f"Error: Video with ID '{args.video_id}' is unavailable.")
    except NoTranscriptFound:
        print(f"Error: No transcript found for video with ID '{args.video_id}'.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
