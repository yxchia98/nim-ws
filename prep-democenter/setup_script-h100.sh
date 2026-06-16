#!/bin/bash

# Ensure NGC API Key is provided
if [ -z "$NGC_API_KEY" ]; then
  echo "NGC_API_KEY is not set. Please enter your NGC API key:"
  read -s NGC_API_KEY
  export NGC_API_KEY
fi

# Ensure Hugging Face API Token is provided
if [ -z "$HF_TOKEN" ]; then
  echo "HF_TOKEN is not set. Please enter your Hugging Face API token:"
  read -s HF_TOKEN
  export HF_TOKEN
fi

# Step 1: Clean the current lab environment
echo "Cleaning current lab environment..."
docker stop $(docker ps -q)
docker system prune -a -f
docker volume prune -a -f
sudo rm -rf ~/app_char_rag.py ~/nvidia-workbench/* ~/Downloads/* ~/Desktop/* /usr/share/ollama/.ollama/models

# Step 2: Login to Docker NGC
echo "Logging into Docker NGC..."
echo "$NGC_API_KEY" | docker login nvcr.io -u '$oauthtoken' --password-stdin

# Step 3: Pull necessary images
IMG_NAME="nvcr.io/nim/meta/llama3-8b-instruct:1.0.3"
TRITON_IMG_NAME="nvcr.io/nvidia/tritonserver:24.06-py3-sdk"
echo "Pulling images..."
docker pull $IMG_NAME
docker pull $TRITON_IMG_NAME

# Step 4: Install common libraries
echo "Installing common libraries..."
sudo apt update
sudo apt install jq zip unzip -y

# Step 5: Download model caches
LOCAL_NIM_CACHE=~/.cache/nim
echo "Setting up model cache directory..."
sudo mkdir -p "$LOCAL_NIM_CACHE"
sudo chmod -R 777 "$LOCAL_NIM_CACHE"

# List available model profiles
echo "Listing model profiles..."
docker run --rm --runtime=nvidia --gpus=all \
	-e NGC_API_KEY=$NGC_API_KEY \
	$IMG_NAME \
	list-model-profiles

# Download normal NIM model cache profile
MODEL_PROFILE="8835c31752fbc67ef658b20a9f78e056914fdef0660206d82f252d62fd96064d"
echo "Downloading NIM model cache for profile $MODEL_PROFILE..."
docker run -it --rm --gpus all \
	-e NGC_API_KEY \
	-v $LOCAL_NIM_CACHE:/opt/nim/.cache \
    $IMG_NAME \
    download-to-cache -p $MODEL_PROFILE

# Download LoRA model cache
LORA_PROFILE="8d3824f766182a754159e88ad5a0bd465b1b4cf69ecf80bd6d6833753e945740"
echo "Downloading LoRA model cache for profile $LORA_PROFILE..."
docker run -it --rm --gpus all \
	-e NGC_API_KEY \
	-v $LOCAL_NIM_CACHE:/opt/nim/.cache \
    $IMG_NAME \
    download-to-cache -p $LORA_PROFILE

# Step 6: Install Hugging Face Tokenizer
echo "Installing Hugging Face library..."
pip install -U huggingface_hub --break-system-packages

# Step 7: Authenticate with Hugging Face
echo "Logging into Hugging Face..."
echo "$HF_TOKEN" | hf auth login

# Step 8: Download tokenizer
TOKENIZER_DIR=~/tokenizer/hub
echo "Downloading tokenizer to $TOKENIZER_DIR..."
mkdir -p $TOKENIZER_DIR
hf download meta-llama/Meta-Llama-3-8B-Instruct --include "*.json" --cache-dir $TOKENIZER_DIR
sudo chmod -R 777 $TOKENIZER_DIR

# Step 9: Download LoRA adapters
LOCAL_PEFT_DIRECTORY=~/nim/loras
echo "Setting up LoRA adapter directory at $LOCAL_PEFT_DIRECTORY..."
mkdir -p $LOCAL_PEFT_DIRECTORY

# Assuming you've downloaded the adapters already into the "prep" directory
echo "Copying LoRA adapters..."
cp -R ./llama3-8b-instruct-lora_vhf-math-v1 \
    ./llama3-8b-instruct-lora_vhf-squad-v1 \
    ./llama3-8b-instruct-lora_vnemo-math-v1 \
    ./llama3-8b-instruct-lora_vnemo-squad-v1 \
    $LOCAL_PEFT_DIRECTORY

# Set permissions for LoRA adapters
sudo chmod -R 777 $LOCAL_PEFT_DIRECTORY

# Step 10: Make environment variables persistent
echo "Saving environment variables to ~/.bashrc and ~/.profile..."

# Add NGC_API_KEY to ~/.bashrc if not already present
if ! grep -q "export NGC_API_KEY=" ~/.bashrc; then
    echo "export NGC_API_KEY=\"$NGC_API_KEY\"" >> ~/.bashrc
    echo "Persisted NGC_API_KEY into ~/.bashrc"
else
    echo "NGC_API_KEY already exists in ~/.bashrc, skipping..."
fi

# Add HF_TOKEN to ~/.bashrc if not already present
if ! grep -q "export HF_TOKEN=" ~/.bashrc; then
    echo "export HF_TOKEN=\"$HF_TOKEN\"" >> ~/.bashrc
    echo "Persisted HF_TOKEN into ~/.bashrc"
else
    echo "HF_TOKEN already exists in ~/.bashrc, skipping..."
fi

# Add NGC_API_KEY to ~/.profile if not already present (for Ubuntu Desktop)
if ! grep -q "export NGC_API_KEY=" ~/.profile; then
    echo "export NGC_API_KEY=\"$NGC_API_KEY\"" >> ~/.profile
    echo "Persisted NGC_API_KEY into ~/.profile"
else
    echo "NGC_API_KEY already exists in ~/.profile, skipping..."
fi

# Add HF_TOKEN to ~/.profile if not already present (for Ubuntu Desktop)
if ! grep -q "export HF_TOKEN=" ~/.profile; then
    echo "export HF_TOKEN=\"$HF_TOKEN\"" >> ~/.profile
    echo "Persisted HF_TOKEN into ~/.profile"
else
    echo "HF_TOKEN already exists in ~/.profile, skipping..."
fi

# Reload bashrc so variables apply immediately
echo "Reloading ~/.bashrc..."
source ~/.bashrc

echo "Environment variables saved persistently!"

echo "Setup completed successfully!"
