# SRE Chatbot - Gemma-3-4B Model

This is a fine-tuned Gemma-3-4B model specialized for Site Reliability Engineering.

## Model Details
- Base Model: mlx-community/gemma-3-270m-bf16
- Adapter Path: ./sre-model
- Fine-tuned for SRE knowledge and Bruno Lucena's technical background

## Usage
This model is optimized for MLX and can be used with the MLX-LM library.

## Ollama Integration
This model can be used with Ollama by creating a Modelfile that references the MLX model.
