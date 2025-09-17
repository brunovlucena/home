# 🤖 Jamie SRE Chatbot

A fine-tuned Large Language Model specialized in Site Reliability Engineering (SRE) knowledge, trained using MLX on macOS. This project creates a custom SRE assistant that can answer questions about reliability engineering, monitoring, incident response, and includes personalized information about Bruno Lucena.

## 🎯 Project Overview

This project fine-tunes the Qwen2.5-1.5B-Instruct model using MLX (Apple's machine learning framework) to create a specialized SRE chatbot. The model is trained on a comprehensive dataset covering SRE principles, practices, and Bruno's technical background.

## 📚 Features

- **SRE Expertise**: Trained on 150+ SRE examples covering:
  - Service Level Indicators (SLIs) and Objectives (SLOs)
  - Error budgets and reliability engineering
  - Monitoring and alerting strategies
  - Incident response procedures
  - Capacity planning and chaos engineering
  - Microservices architecture patterns

- **Personalized Knowledge**: Includes information about Bruno Lucena's technical preferences and background
- **Ollama Integration**: Exports to Ollama format for easy deployment
- **MLX Optimization**: Leverages Apple Silicon for efficient training and inference
- **Logfire Observability**: Comprehensive monitoring with structured logging, metrics, and distributed tracing

## 🚀 Quick Start

### Prerequisites

- macOS with Apple Silicon (M1/M2/M3)
- Python 3.8+
- [uv](https://github.com/astral-sh/uv) package manager
- [Ollama](https://ollama.ai/) (for model deployment)
- [Logfire](https://logfire.pydantic.dev/) account (for observability)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd jamie-sre-chatbot

# Install dependencies
make install
```

### Training the Model

```bash
# Train the SRE model (this will take some time)
make train

# Or train and test in one command
make train-and-test
```

### Testing the Model

```bash
# Test the trained model
make test
```

### Deploy to Ollama

```bash
# Export to Ollama format and create model
make create-ollama

# Test the Ollama model
ollama run bruno-sre "What is Site Reliability Engineering?"
```

## 📋 Available Commands

| Command | Description |
|---------|-------------|
| `make install` | Install all dependencies |
| `make train` | Train the SRE model |
| `make test` | Test the trained model |
| `make train-and-test` | Train and test in sequence |
| `make export-ollama` | Export model to Ollama format |
| `make create-ollama` | Export and create model in Ollama |
| `make clean` | Clean up generated files |
| `make dataset-info` | Show dataset information |
| `make help` | Show all available commands |

## 🏗️ Project Structure

```
jamie-sre-chatbot/
├── README.md                 # This file
├── Makefile                  # Build automation
├── requirements.txt          # Python dependencies
├── sre_dataset.json         # Training dataset (150+ examples)
├── train_sre_model.py       # Main training script
├── export_ollama.py         # Ollama export utility
└── sre-model/               # Generated model directory
```

## 🎓 Training Process

The model is fine-tuned using:

- **Base Model**: `mlx-community/Qwen2.5-1.5B-Instruct-4bit`
- **Method**: LoRA (Low-Rank Adaptation) for efficient fine-tuning
- **Dataset**: 150+ SRE examples + Bruno's personal information
- **Training**: 500 iterations with 2e-5 learning rate
- **Format**: ChatML format for better instruction following

## 🧪 Testing Examples

The model can answer questions like:

- "What is Site Reliability Engineering?"
- "How do you calculate SLIs and SLOs?"
- "Tell me about Bruno Lucena"
- "How do you troubleshoot high error rates?"
- "What are the key principles of SRE?"
- "How do you implement canary deployments?"

## 🔧 Customization

### Training Parameters

You can customize training by modifying the parameters in `train_sre_model.py`:

```python
# Training configuration
batch_size = 2
iterations = 500
learning_rate = 2e-5
max_seq_length = 1024
```

### Dataset

The training dataset (`sre_dataset.json`) contains structured examples in the format:

```json
{
  "instruction": "Question or prompt",
  "output": "Expected response"
}
```

To add more examples, simply extend the dataset with new instruction-output pairs.

## 🌐 Ollama Deployment

The model is configured to work with your Ollama server at `192.168.0.3:11434`. After training and export:

1. The model is exported to `./sre-model-ollama/`
2. A `Modelfile` is created for Ollama
3. Instructions are saved to `OLLAMA_INSTRUCTIONS.txt`

## 🔥 Logfire Observability

The chatbot includes comprehensive Logfire instrumentation for monitoring and debugging:

### Setup Logfire

```bash
# Get your Logfire token from https://logfire.pydantic.dev/dashboard
export LOGFIRE_TOKEN="your-token-here"

# Run the setup script
./setup-logfire.sh
```

### What's Monitored

- **AI Model Performance**: Response times, error rates, response quality
- **Slack Interactions**: Mentions, slash commands, direct messages
- **System Health**: Startup status, memory usage, error tracking
- **User Analytics**: Usage patterns, popular questions, engagement metrics

### Viewing Metrics

1. Visit [Logfire Dashboard](https://logfire.pydantic.dev/dashboard)
2. Look for service: `jamie-sre-chatbot`
3. Monitor real-time metrics, traces, and logs

For detailed information, see [LOGFIRE_INSTRUMENTATION.md](LOGFIRE_INSTRUMENTATION.md).

## 📖 Tutorial Reference

This project follows the tutorial: [Train Your Own LLM on MacBook: A 15-Minute Guide with MLX](https://medium.com/@dummahajan/train-your-own-llm-on-macbook-a-15-minute-guide-with-mlx-6c6ed9ad036a)

## 🤝 Contributing

To add more SRE knowledge or improve the dataset:

1. Edit `sre_dataset.json` with new examples
2. Retrain the model: `make train`
3. Test the improvements: `make test`
4. Deploy to Ollama: `make create-ollama`

## 📄 License

This project is part of Bruno Lucena's personal development workspace.

---

**Bruno Lucena**: A vibecoder 🎵💻
