#!/usr/bin/env python3
"""
Simple SRE Model Fine-tuning with MLX
Following the tutorial: https://medium.com/@dummahajan/train-your-own-llm-on-macbook-a-15-minute-guide-with-mlx-6c6ed9ad036a
"""

import json
import mlx.core as mx
from mlx_lm import load, generate
from mlx_lm.tuner import lora
import argparse

def load_sre_dataset(file_path: str):
    """Load the SRE dataset"""
    with open(file_path, 'r') as f:
        data = json.load(f)
    
    # Convert to text format for training
    training_texts = []
    for item in data:
        text = f"<|im_start|>user\n{item['instruction']}<|im_end|>\n<|im_start|>assistant\n{item['output']}<|im_end|>"
        training_texts.append(text)
    
    return training_texts

def save_training_data(texts: list, output_dir: str):
    """Save training data in JSONL format for MLX-LM"""
    import os
    import json
    import random
    
    # Create directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Split data into train and validation (80/20)
    random.shuffle(texts)
    split_idx = int(len(texts) * 0.8)
    train_texts = texts[:split_idx]
    valid_texts = texts[split_idx:]
    
    # Save training data
    train_file = os.path.join(output_dir, "train.jsonl")
    with open(train_file, 'w') as f:
        for text in train_texts:
            data = {"text": text.strip()}
            f.write(json.dumps(data) + "\n")
    
    # Save validation data
    valid_file = os.path.join(output_dir, "valid.jsonl")
    with open(valid_file, 'w') as f:
        for text in valid_texts:
            data = {"text": text.strip()}
            f.write(json.dumps(data) + "\n")
    
    print(f"   Saved training data to {train_file} ({len(train_texts)} examples)")
    print(f"   Saved validation data to {valid_file} ({len(valid_texts)} examples)")
    return output_dir

def main():
    parser = argparse.ArgumentParser(description="Train SRE model with MLX")
    parser.add_argument("--dataset", default="sre_dataset.json", help="SRE dataset file")
    parser.add_argument("--model", default="mlx-community/Qwen2.5-1.5B-Instruct-4bit", help="Base model to fine-tune")
    parser.add_argument("--train", action="store_true", help="Train the model")
    parser.add_argument("--test", action="store_true", help="Test the trained model")
    parser.add_argument("--model_path", default="./sre-model", help="Path to save/load the model")
    
    args = parser.parse_args()
    
    print("🤖 SRE Model Training with MLX")
    print("=" * 50)
    
    if args.train:
        print("📚 Loading SRE dataset...")
        training_texts = load_sre_dataset(args.dataset)
        print(f"   Loaded {len(training_texts)} examples")
        
        # Save training data in JSONL format
        training_dir = "sre_training_data"
        save_training_data(training_texts, training_dir)
        
        print("🚀 Starting fine-tuning...")
        print(f"   Base model: {args.model}")
        print(f"   Output path: {args.model_path}")
        
        # Fine-tune using LoRA via CLI
        import subprocess
        import sys
        
        cmd = [
            sys.executable, "-m", "mlx_lm.lora",
            "--model", args.model,
            "--train",
            "--data", training_dir,
            "--adapter-path", args.model_path,
            "--batch-size", "2",
            "--iters", "500",
            "--learning-rate", "2e-5",
            "--steps-per-report", "50",
            "--steps-per-eval", "100",
            "--max-seq-length", "1024"
        ]
        
        print(f"Running command: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Training failed with error: {result.stderr}")
            return
        else:
            print("Training completed successfully!")
            print(result.stdout)
        
        print("✅ Training completed!")
        print(f"Model saved to: {args.model_path}")
    
    if args.test:
        print("\n🧪 Testing the fine-tuned model...")
        print("=" * 50)
        
        # Load the base model and apply adapter
        from mlx_lm import load
        base_model = args.model
        model, tokenizer = load(base_model, adapter_path=args.model_path)
        
        # Test prompts
        test_prompts = [
            "What is Site Reliability Engineering?",
            "How do you calculate SLIs?",
            "Tell me about Bruno Lucena",
            "How do you troubleshoot high error rates?",
            "What are the key principles of SRE?",
            "How do you implement canary deployments?"
        ]
        
        for prompt in test_prompts:
            print(f"\n❓ Prompt: {prompt}")
            
            # Generate response using MLX-LM generate
            from mlx_lm import generate
            
            response = generate(
                model, 
                tokenizer, 
                prompt=f"<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant\n",
                max_tokens=200
            )
            
            print(f"🤖 Response: {response}")
            print("-" * 50)
    
    print("\n🎉 Done!")

if __name__ == "__main__":
    main()
