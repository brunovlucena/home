#!/usr/bin/env python3
"""
Export fine-tuned SRE model to Ollama format
"""

import argparse
import os
import json
from mlx_lm import load, convert

def export_to_ollama(base_model: str, adapter_path: str, output_path: str = "./sre-model-ollama"):
    """Export the fine-tuned model to Ollama format"""
    print("📦 Exporting SRE model to Ollama format...")
    print(f"   Base model: {base_model}")
    print(f"   Adapter path: {adapter_path}")
    print(f"   Output path: {output_path}")
    
    # Clean up existing output directory
    if os.path.exists(output_path):
        print(f"🗑️  Cleaning up existing directory: {output_path}")
        import shutil
        shutil.rmtree(output_path)
    
    # Load the fine-tuned model and merge adapters
    print("🔄 Loading and merging fine-tuned model...")
    import shutil
    import subprocess
    import sys
    
    # Download the base model directly from HuggingFace (not MLX)
    print("🔄 Downloading base model from HuggingFace...")
    from huggingface_hub import snapshot_download
    # Extract the actual model name from the MLX model path
    model_name = base_model.split("/")[-1].replace("-4bit", "")
    hf_model_name = f"Qwen/{model_name}"
    temp_base_path = output_path + "_temp"
    snapshot_download(repo_id=hf_model_name, local_dir=temp_base_path)
    
    # Merge the LoRA adapters with the base model using MLX-LM CLI
    print("🔄 Merging LoRA adapters with base model...")
    cmd = [
        sys.executable, "-m", "mlx_lm.fuse",
        "--model", temp_base_path,
        "--adapter-path", adapter_path,
        "--save-path", output_path
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error merging adapters: {result.stderr}")
        raise RuntimeError("Failed to merge adapters")
    
    # Clean up temporary directory
    shutil.rmtree(temp_base_path)
    print("   Merged adapters with base model")
    
    # Create a Modelfile for Ollama using the converted model
    modelfile_path = os.path.join(output_path, "Modelfile")
    absolute_path = os.path.abspath(output_path)
    with open(modelfile_path, 'w') as f:
        f.write(f"""FROM {absolute_path}
TEMPLATE \"\"\"### Instruction:
{{{{ .Prompt }}}}

### Response:
\"\"\"
SYSTEM \"\"\"You are a helpful Site Reliability Engineering (SRE) assistant. You have been fine-tuned on SRE knowledge and can answer questions about:

- Site Reliability Engineering principles
- Service Level Indicators (SLIs) and Service Level Objectives (SLOs)
- Monitoring and alerting
- Incident response
- Capacity planning
- Chaos engineering
- Microservices architecture
- Bruno Lucena's technical preferences and background

Always provide accurate, helpful responses based on your training data.\"\"\"
""")
    
    print(f"✅ Model exported successfully!")
    print(f"   Output directory: {output_path}")
    print(f"   Modelfile created: {modelfile_path}")
    
    # Create instructions for Ollama import
    instructions = f"""
📋 Ollama Import Instructions:

1. Copy the model directory to your Ollama server (192.168.0.3):
   scp -r {output_path} user@192.168.0.3:/path/to/ollama/models/

2. On the Ollama server, create the model:
   ollama create sre-chatbot:latest -f {output_path}/Modelfile

3. Test the model:
   ollama run sre-chatbot:latest "Who is Bruno Lucena?"

4. The model will be available at: 192.168.0.3:11434

📋 Local Ollama Commands (if running locally):
   ollama create sre-chatbot:latest -f {output_path}/Modelfile
   ollama run sre-chatbot:latest "Who is Bruno Lucena?"
"""
    
    print(instructions)
    
    # Save instructions to file
    with open("OLLAMA_INSTRUCTIONS.txt", 'w') as f:
        f.write(instructions)
    
    print("📄 Instructions saved to OLLAMA_INSTRUCTIONS.txt")

def main():
    parser = argparse.ArgumentParser(description="Export SRE model to Ollama format")
    parser.add_argument("--model", default="mlx-community/Qwen2.5-1.5B-Instruct-4bit", help="Base model")
    parser.add_argument("--adapter-path", default="./sre-model", help="Path to fine-tuned adapter")
    parser.add_argument("--output", default="./sre-model-ollama", help="Output directory for Ollama model")
    
    args = parser.parse_args()
    
    export_to_ollama(args.model, args.adapter_path, args.output)

if __name__ == "__main__":
    main()
