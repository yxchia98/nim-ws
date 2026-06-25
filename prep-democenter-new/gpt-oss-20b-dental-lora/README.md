---
license: apache-2.0
base_model: openai/gpt-oss-20b
tags:
- dental
- healthcare
- medical
- lora
- peft
- fine-tuned
- dentistry
- dental ai
- clinical decision support
- treatment planning
- diagnosis
- clinical reasoning
- patient evaluation
- evidence based
- dental assistant
- chairside assistant
- risk assessment
- triage
- qlora
- gpt-oss-20b
- text-generation
pretty_name: Dental AI Model 20B - Clinical Decision Support LoRA
pipeline_tag: text-generation
library_name: peft
language:
- en
datasets:
- Wildstash/dental-treatment-planning-2.5k
- Wildstash/dental-2.5k-instruct
---

# dental-gpt-qlora

A fine-tuned LoRA adapter for openai/gpt-oss-20b specialized in dental patient evaluations and clinical decision-making.

## Model Details

- **Base Model**: openai/gpt-oss-20b
- **Fine-tuning Method**: QLoRA (Quantized Low-Rank Adaptation)
- **Training Data**: 2,494 dental patient cases
- **Trainable Parameters**: 192 parameters (0.0761% of base model)
- **Training Framework**: PyTorch + PEFT

## Training Configuration

- **LoRA Rank**: 32
- **LoRA Alpha**: 64
- **LoRA Dropout**: 0.05
- **Learning Rate**: 1e-5
- **Batch Size**: 2 (effective batch size: 32)
- **Epochs**: 2
- **Max Sequence Length**: 4096

## Usage

```python
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel

# Load base model
base_model = AutoModelForCausalLM.from_pretrained(
    "openai/gpt-oss-20b",
    device_map="auto",
    torch_dtype=torch.bfloat16,
    trust_remote_code=True
)

# Load tokenizer
tokenizer = AutoTokenizer.from_pretrained("openai/gpt-oss-20b", trust_remote_code=True)

# Load LoRA adapter
model = PeftModel.from_pretrained(base_model, "Wildstash/dental-gpt-qlora")

# Example usage
messages = [
    {"role": "system", "content": "You are an expert dental clinician providing comprehensive patient care."},
    {"role": "user", "content": "Please evaluate this dental patient: 45M with severe tooth pain, swelling, fever 101°F."}
]

input_text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
inputs = tokenizer(input_text, return_tensors="pt").to(model.device)

with torch.no_grad():
    outputs = model.generate(
        **inputs,
        max_new_tokens=500,
        temperature=0.7,
        do_sample=True,
        pad_token_id=tokenizer.eos_token_id
    )

response = tokenizer.decode(outputs[0][inputs['input_ids'].shape[1]:], skip_special_tokens=True)
print(response)
```

## Training Data

The model was fine-tuned on 2,494 dental patient cases covering:
- Emergency dental situations
- Periodontal disease management
- Pediatric dental care
- Oral pathology evaluation
- Treatment planning and follow-up care

## Performance

The fine-tuned model demonstrates improved:
- Structured clinical responses
- Evidence-based treatment recommendations
- Appropriate urgency assessment
- Patient safety considerations
- Clinical guideline adherence

## Limitations

- This model is for educational/research purposes only
- Not intended for direct clinical decision-making
- Always consult with qualified dental professionals
- May not cover all dental specialties or rare conditions

## Citation

If you use this model, please cite:

```bibtex
@misc{dental-gpt-qlora,
  title={Dental GPT: A Fine-tuned Language Model for Dental Clinical Decision Support},
  author={Your Name},
  year={2024},
  url={https://huggingface.co/Wildstash/dental-gpt-qlora}
}
```
