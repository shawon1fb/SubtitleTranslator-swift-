# SubtitleTranslator

A command-line tool for translating subtitle (.srt) files from English to Bangla using various LLM providers.

## Features

- Translate subtitle files from English to Bangla
- Support for multiple LLM providers:
  - Ollama (local LLM)
  - OpenAI ChatGPT
  - Anthropic Claude
  - DeepSeek
- Configurable settings with persistent configuration
- Interactive configuration mode

## Installation

### Prerequisites

- macOS 13 or later
- Swift 5.9 or later

### Building from Source

1. Clone the repository
2. Build the project:

```bash
cd SubtitleTranslator
swift build -c release
```

3. The executable will be available at `.build/release/SubtitleTranslator`

### Installation (optional)

To make the tool available system-wide:

```bash
cp .build/release/SubtitleTranslator /usr/local/bin/
```

## Usage

### Basic Translation

```bash
SubtitleTranslator translate --input path/to/subtitle.srt
```

This will create a translated file named `subtitle.bn.srt` in the same directory.

### Specifying Output Location

```bash
SubtitleTranslator translate --input path/to/subtitle.srt --output path/to/output.srt
```

### Using a Specific LLM Provider

```bash
SubtitleTranslator translate --input path/to/subtitle.srt --llm chatgpt --api-key YOUR_API_KEY
```

Supported LLM providers: `ollama`, `chatgpt`, `claude`, `deepseek`

### Using Ollama (Local LLM)

```bash
SubtitleTranslator translate --input path/to/subtitle.srt --llm ollama --ollama-endpoint http://localhost:11434 --ollama-model llama3.2:latest
```

## Configuration

You can configure default settings to avoid typing the same options repeatedly.

### Interactive Configuration

```bash
SubtitleTranslator config --interactive
```

This will guide you through setting up your preferred defaults.

### View Current Configuration

```bash
SubtitleTranslator config --view
```

### Set Individual Configuration Options

```bash
SubtitleTranslator config --llm claude --api-key YOUR_API_KEY
SubtitleTranslator config --ollama-model llama3.2:latest
SubtitleTranslator config --output-dir ~/Documents/Subtitles
```

### Clear Configuration

```bash
SubtitleTranslator config --clear
```

## LLM Provider Setup

### Ollama (Default)

1. Install Ollama from [ollama.ai](https://ollama.ai)
2. Pull the Llama model: `ollama pull llama3.2:latest`
3. Ensure Ollama is running locally

### OpenAI ChatGPT

1. Get an API key from [OpenAI](https://platform.openai.com)
2. Configure the tool: `SubtitleTranslator config --llm chatgpt --api-key YOUR_API_KEY`

### Anthropic Claude

1. Get an API key from [Anthropic](https://console.anthropic.com)
2. Configure the tool: `SubtitleTranslator config --llm claude --api-key YOUR_API_KEY`

### DeepSeek

1. Get an API key from [DeepSeek](https://platform.deepseek.com)
2. Configure the tool: `SubtitleTranslator config --llm deepseek --api-key YOUR_API_KEY`

## License

License pending. This project currently does not have a license.