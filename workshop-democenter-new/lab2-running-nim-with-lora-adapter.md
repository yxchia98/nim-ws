# 🧪 Lab Guide 02: Running NVIDIA NIM with LoRA (Low-Rank Adaptation)

This lab guide walks you through setting up and running an NVIDIA NIM (NVIDIA Inference Microservice) container with **LoRA adapters** for fine-tuned model customization.
You’ll learn how to configure the environment, launch the container, and query LoRA-enabled models.

---

## 🧩 Prerequisites

Before starting, ensure you have the following:

* **Docker** (with NVIDIA Container Toolkit installed)
* **NGC API key** (for accessing NVIDIA’s NGC registry)
* **GPU-enabled system**
* **LoRA adapter files**

---

## Step 1: Stop All Running Containers

Before starting a new container, it’s best to stop any previously running containers to avoid port conflicts or GPU contention.

```bash
docker stop $(docker ps -q)
```

This command stops all running Docker containers.
If no containers are running, you’ll see a harmless error message.

---

## Step 2: Set Up the LoRA Directory

Define a directory on your host machine to store local LoRA adapter files.

```bash
export LOCAL_PEFT_DIRECTORY=~/nim/loras
mkdir -p $LOCAL_PEFT_DIRECTORY
ls $LOCAL_PEFT_DIRECTORY
```
![lora-adapters](./democenter-images/lab2-lora-adapters-new.png)

You will see 2 LoRA adapters, we will be loading these adapters onto our NIM later.

**Explanation:**

* `LOCAL_PEFT_DIRECTORY` points to where your LoRA weights/adapters will be stored.
* `mkdir -p` ensures the directory exists (creates it if missing).
* The `ls` command confirms it’s created correctly.

---

## Step 3: Configure NIM Runtime Variables

Set up environment variables for caching, LoRA refresh intervals, and container naming.

```bash
export LOCAL_NIM_CACHE=~/.cache/nim
mkdir -p "$LOCAL_NIM_CACHE"

export NIM_PEFT_REFRESH_INTERVAL=3600      # Refresh LoRA adapters every 1 hour
export NIM_PEFT_SOURCE=/opt/nim/loras          # Inside-container LoRA path
export CONTAINER_NAME=gpt-oss-20b  # Name of the NIM container
# export NIM_MODEL_PROFILE=9dd35140a6fa83cbb0dbe132885f2b22da0dc8082a124d7f65fad7328b374d9f
```

**Explanation:**

* `LOCAL_NIM_CACHE` → Local cache directory for NIM models and metadata.
* `NIM_PEFT_REFRESH_INTERVAL` → Automatically refreshes LoRA adapters every 3600 seconds.
* `NIM_PEFT_SOURCE` → Directory inside the container that maps to LoRA files.
* `CONTAINER_NAME` → Container name for easier management.
* `NIM_MODEL_PROFILE` → The LoRA profile that we will be using.

---

## Step 4: Run NIM with LoRA Support

Now we can start running an instance of NIM with LoRA support profile:

```bash
docker run -itd --rm --name=gpt-oss-20b --gpus all \
  -v "$LOCAL_NIM_CACHE:/opt/nim/.cache" \
  -v "$LOCAL_PEFT_DIRECTORY:/opt/nim/loras" \
  -p 8000:8000 \
  -e NGC_API_KEY \
  -e NIM_PEFT_SOURCE=/opt/nim/loras \
  -e NIM_PEFT_REFRESH_INTERVAL=10 \
  nvcr.io/nim/openai/gpt-oss-20b:2.0.6
```

**Explanation:**

* `--gpus all` enables GPU acceleration.
* `--shm-size=16GB` ensures sufficient shared memory for large models.
* `-v` mounts host directories into the container.
* `-e` sets environment variables for NIM configuration.
* `-p 8000:8000` exposes the inference API on port 8000.

It will take a while for the model to be deployed (around 1~5 mins). Run the following command to continuously check for GPU utilization, and you should see something like the following:
```bash
watch nvidia-smi
```
![nvidia-smi-output](./democenter-images/lab2-nvidia-smi-new.png)

Once launched, the container will begin serving the NIM API. 

Press `CTRL + C` to go back and proceed to step 5.


---

## Step 5: List Available LoRA Adapters

Check which LoRA adapters are available and ready for inference.

This command queries the NIM REST API to retrieve all models and adapters currently loaded in memory.


```bash
curl -X GET 'http://0.0.0.0:8000/v1/models' | jq
```
![lora-endpoint](./democenter-images/lab2-lora-endpoint-new.png)

You will see a response list of models and the lora adapters loaded. Over here we see the `gpt-oss-20b-multilingual-reasoner` and `gpt-oss-20b-dental-lora` adapter which has `openai/gpt-oss-20b` as its parent model. There is also the default model without adapters on it.

---

## Step 6: Query a normal NIM (without LoRA)

You can now send a test prompt to the model.
Before we leverage on a dental LoRA adapter, lets test out the normal model with a dental patient diagnosis scenario:

```bash
curl -X 'POST' \
  'http://0.0.0.0:8000/v1/chat/completions' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
      "model": "openai/gpt-oss-20b",
      "messages": [
      {"role": "system", "content": "You are an expert dental clinician providing comprehensive patient care."},
      {"role":"user", "content":"Please evaluate this dental patient: 45M with severe tooth pain, swelling, fever 101°F."}
      ],
      "max_tokens": 1024
  }' | jq
```
![nim-query](./democenter-images/lab2-nim-query-new.png)

### As you can see, the output is good but still rather general. It says a lot of things but does not give a direct diagnosis nor medication plan for patient care.

---

## Step 7: Query a LoRA-Enhanced Model

Now lets send a test prompt to the model that uses the fine-tuned dental LoRA adapter.
This example uses a dental LoRA adapter (`gpt-oss-20b-dental-lora`):

```bash
curl -X 'POST' \
  'http://0.0.0.0:8000/v1/chat/completions' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
      "model": "gpt-oss-20b-dental-lora",
      "messages": [
      {"role": "system", "content": "You are an expert dental clinician providing comprehensive patient care."},
      {"role":"user", "content":"Please evaluate this dental patient: 45M with severe tooth pain, swelling, fever 101°F."}
      ],
      "max_tokens": 1024
  }' | jq
```
![nim-lora-query](./democenter-images/lab2-lora-query-new.png)

### Now with the fine-tuned LoRA adapter loaded and queried, we can see a better response that gives us more direct information that we are seeking for.

---

## ✅ Summary

In this lab, you have successfully:

* Set up directories for LoRA storage and caching.
* Configured environment variables for NIM runtime.
* Launched the NIM container with GPU support.
* Queried and tested a LoRA-enhanced model through the REST API.

---
