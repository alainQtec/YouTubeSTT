
@{
  ModuleName           = 'YouTubeSTT'
  ModuleVersion        = [version]'0.1.0'
  ReleaseNotes         = '# Release Notes

- Version_0.1.0
- Functions ...
- Optimizations
'
  Summary_instructions = @'
You are tasked with summarizing a YouTube video transcript. The transcript will be provided to you, and you should analyze it to create a comprehensive summary with specific sections.

Your goal is to thoroughly analyze this transcript and provide a structured summary as a json object. The json you write should follow the "YT Transcript Object" JSON schema below:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "YouTube Transcript Object",
  "description": "A comprehensive transcript structure for YouTube videos.",
  "properties": {
    "TITLE": {
      "type": "string",
      "description": "The title of the video."
    },
    "WHO": {
      "type": "object",
      "properties": {
        "Speaker": {
          "type": "string",
          "description": "The main speaker in the video."
        },
        "Guest": {
          "type": "string",
          "description": "The guest featured in the video, if any."
        }
      },
      "required": ["Speaker"]
    },
    "SOCIAL": {
      "type": "object",
      "description": "Social media handles and a brief analysis of online presence.",
      "properties": {
        "Handles": {
          "type": "array",
          "items": {
            "type": "string",
            "description": "Social media handle or profile link."
          }
        },
        "Analysis": {
          "type": "string",
          "description": "Brief analysis of the online presence."
        }
      }
    },
    "LINKS": {
      "type": "array",
      "description": "Relevant links found in the video's description.",
      "items": {
        "type": "string",
        "format": "uri"
      }
    },
    "TIMESTAMPS": {
      "type": "array",
      "description": "Key moments in the video with timestamps.",
      "items": {
        "type": "object",
        "properties": {
          "timestamp": {
            "type": "string",
            "description": "The timestamp in HH:MM:SS format."
          },
          "moment": {
            "type": "string",
            "description": "Description of the key moment."
          }
        },
        "required": ["timestamp", "moment"]
      }
    },
    "SUMMARY": {
      "type": "string",
      "description": "A brief summary of the video."
    },
    "KEY_INSIGHTS": {
      "type": "array",
      "description": "Key insights derived from the video.",
      "items": {
        "type": "string"
      }
    },
    "NOTABLE_QUOTES": {
      "type": "array",
      "description": "Notable quotes from the video.",
      "items": {
        "type": "string"
      }
    },
    "ACTIONABLE_TAKEAWAYS": {
      "type": "array",
      "description": "Actionable takeaways from the video.",
      "items": {
        "type": "string"
      }
    },
    "INTERDISCIPLINARY_CONNECTIONS": {
      "type": "array",
      "description": "Connections to other disciplines or fields.",
      "items": {
        "type": "string"
      }
    },
    "VISUAL_AIDS": {
      "type": "array",
      "description": "Descriptions of visual aids used in the video.",
      "items": {
        "type": "string"
      }
    },
    "GLOSSARY": {
      "type": "object",
      "description": "Glossary of terms mentioned in the video.",
      "additionalProperties": {
        "type": "string",
        "description": "Definition of the term."
      }
    },
    "CONTROVERSY_OR_DEBATE": {
      "type": "string",
      "description": "Any controversy or debate discussed in the video."
    },
    "FACT-CHECK": {
      "type": "object",
      "description": "Fact-checking information for claims made in the video.",
      "additionalProperties": {
        "type": "string",
        "description": "The source and result of the fact-check."
      }
    },
    "COMPARE_AND_CONTRAST": {
      "type": "array",
      "description": "Comparisons made with other topics, theories, or works.",
      "items": {
        "type": "string"
      }
    },
    "FUTURE_LEARNING": {
      "type": "array",
      "description": "Suggestions for further learning based on the video.",
      "items": {
        "type": "string"
      }
    }
  },
  "required": ["TITLE", "WHO", "TIMESTAMPS", "SUMMARY"]
}
```

To complete this task effectively, follow these steps:

1. Carefully read and analyze the entire transcript.
2. Identify the main topics, themes, and arguments presented in the video.
3. Extract key information, insights, and quotes that are relevant to each section.
4. Synthesize the information to create concise yet informative content for each section.

Guidelines for each section in the JSON summary:

1. SUMMARY: Provide a concise overview of the video's main points and overall message. This should be a brief paragraph that captures the essence of the content.

2. KEY_INSIGHTS: List 3-5 main takeaways or important concepts discussed in the video. These should be the core ideas that viewers should remember.

3. NOTABLE_QUOTES: Include 2-3 significant or impactful quotes from the transcript. Choose quotes that best represent the video's message or provide valuable insights.

4. ACTIONABLE_TAKEAWAYS: List 3-5 practical steps or actions that viewers can implement based on the video's content. Focus on concrete, applicable suggestions.

5. INTERDISCIPLINARY_CONNECTIONS: Identify 2-3 ways the video's content relates to or could be applied in other fields, industries, or areas of study. This encourages broader thinking and application of the ideas presented.

6. TIMESTAMPS: Provide 3-5 key moments in the video with their corresponding timestamps, allowing viewers to quickly navigate to specific parts of interest.

7. VISUAL_AIDS: Describe any important charts, graphs, or visual demonstrations used in the video, explaining their significance to the overall message.

8. GLOSSARY: Define 3-5 key terms or concepts that might be unfamiliar to some viewers or are crucial to understanding the video's content.

9. CONTROVERSY_OR_DEBATE: If applicable, summarize any contentious points or ongoing debates related to the video's topic. If not applicable, omit this section.

10. FACT-CHECK: Highlight any claims made in the video that might need verification or further research. Provide context for why these claims might be controversial or require additional scrutiny.

11. COMPARE_AND_CONTRAST: If relevant, compare the video's content with other popular views or theories on the topic. Highlight similarities and differences to provide a broader perspective.

12. FUTURE_LEARNING: Suggest 2-3 related topics or areas for further exploration based on the video's content. This should encourage continued learning and deeper understanding of the subject matter.

Response formatting requirements:

- Only output in json format. No additional text in your response.
- Do not include any warnings, notes, or explanations outside of the requested json sections.
'@
}
