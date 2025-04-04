import os
import torch
import logging
import argparse
import transformers
from transformers import Trainer
import torch.distributed as dist
from utils import training_datasets
from dataclasses import dataclass, field
from typing import Dict, Optional, Sequence
from peft import get_peft_model, PeftConfig


IGNORE_INDEX = -100 #default ignore_index = 100 in transformers
logging.basicConfig(level=logging.DEBUG)  
@dataclass
class ModelArguments:
    model_name_or_path: Optional[str] = field(default="facebook/opt-125m")
    use_flash_attention: bool = field(default=False, metadata={"help": "Whether to use Flash Attention."})

@dataclass
class DataArguments:
    data_path: str = field(default=None, metadata={"help": "Path to the training data."})


@dataclass
class TrainingArguments(transformers.TrainingArguments):
    cache_dir: Optional[str] = field(default=None)
    optim: str = field(default="adamw_torch")
    model_max_length: int = field(
        default=512,
        metadata={"help": "Maximum sequence length. Sequences will be right padded (and possibly truncated)."},
    )
    truncate_source: bool = field(default=False)
    use_peft: bool = field(default=False)
    peft_config_path: str = field(default=None)


@dataclass
class DataCollatorForSupervisedDataset(object):
    """Collate examples for supervised fine-tuning."""

    tokenizer: transformers.PreTrainedTokenizer

    def __call__(self, instances: Sequence[Dict]) -> Dict[str, torch.Tensor]:
        input_ids, labels = tuple([instance[key] for instance in instances] for key in ("input_ids", "labels"))
        input_ids = torch.nn.utils.rnn.pad_sequence(
            input_ids, batch_first=True, padding_value=self.tokenizer.pad_token_id
        )
        labels = torch.nn.utils.rnn.pad_sequence(labels, batch_first=True, padding_value=IGNORE_INDEX)
        return dict(
            input_ids=input_ids,
            labels=labels,
            attention_mask=input_ids.ne(self.tokenizer.pad_token_id),
        )


def make_supervised_data_module(tokenizer: transformers.PreTrainedTokenizer, args) -> Dict:
    """Make dataset and collator for supervised fine-tuning."""
    train_dataset = training_datasets.SupervisedDataset(tokenizer=tokenizer, data_path=args.data_path, args=args)
    data_collator = DataCollatorForSupervisedDataset(tokenizer=tokenizer)
    return dict(train_dataset=train_dataset, eval_dataset=None, data_collator=data_collator)


def is_master():
    return dist.get_rank() == 0


class SaveModelCallback(transformers.TrainerCallback):
    def on_save(self, args, state, control, **kwargs):
        output_dir = args.output_dir
        step = state.global_step
        if is_master():
            print(f"Model saved at: {output_dir}/checkpoint-{step}/")
        return control

def find_latest_checkpoint(output_dir):
    """Find the latest checkpoint in the output directory."""
    if not os.path.exists(output_dir):
        return None
    checkpoints = [d for d in os.listdir(output_dir) if d.startswith("checkpoint-")]
    if not checkpoints:
        return None
    latest_checkpoint = max(checkpoints, key=lambda x: int(x.split("-")[-1]))
    return os.path.join(output_dir, latest_checkpoint)


class CustomTrainer(Trainer):
    def log(self, logs: Dict[str, float], start_time: Optional[float] = None) -> None:
        """
        Log `logs` on the various objects watching training.


        Subclass and override this method to inject custom behavior.

        Args:
            logs (`Dict[str, float]`):
                The values to log.
        """
        if self.state.epoch is not None:
            logs["epoch"] = self.state.epoch
        if self.args.include_num_input_tokens_seen:
            logs["num_input_tokens_seen"] = self.state.num_input_tokens_seen

        output = {**logs, **{"step": self.state.global_step}}
        self.state.log_history.append(output)
        self.control = self.callback_handler.on_log(self.args, self.state, self.control, logs)

# import matplotlib.pyplot as plt

class LoggingCallback(transformers.TrainerCallback):
    def __init__(self):
        self.losses = []
        self.lr_schedules = []
        self.grad_norms = []
        self.steps = []
        
    def on_log(self, args, state, control, logs=None, **kwargs):
        if logs is not None:
            current_step = state.global_step
            if "loss" in logs:
                self.losses.append(logs["loss"])
                self.steps.append(current_step)
            if "learning_rate" in logs:
                self.lr_schedules.append(logs["learning_rate"])
            if "grad_norm" in logs:
                grad_norm = logs["grad_norm"]
                self.grad_norms.append(grad_norm)
            print(logs)

        import pickle
        with open("data_syn_gen_func_call.pkl", "wb") as f:
            pickle.dump({
                "losses": self.losses,
                "lr": self.lr_schedules,
                "grad_norms": self.grad_norms,
                "steps": self.steps
            }, f)

        # plt.figure(figsize=(10, 5))
        # plt.subplot(1, 3, 1)
        # plt.plot(self.steps, self.losses, label="Loss")
        # plt.xlabel("Training Steps")
        # plt.ylabel("Loss")
        # plt.title("Loss vs Training Step")

        # # Plot the learning rate schedule vs training step
        # plt.subplot(1, 3, 2)
        # plt.plot(self.steps, self.lr_schedules, label="Learning Rate")
        # plt.xlabel("Training Steps")
        # plt.ylabel("Learning Rate")
        # plt.title("LR Schedule vs Training Step")

        # # Plot the gradient norm vs training step
        # plt.subplot(1, 3, 3)
        # plt.plot(self.steps, self.grad_norms, label="Gradient Norm")
        # plt.xlabel("Training Steps")
        # plt.ylabel("Gradient Norm")
        # plt.title("Gradient Norm vs Training Step")

        # plt.tight_layout()
        # plt.savefig("syn_gen_func_call.png")
        # plt.close()

def train():
    parser = transformers.HfArgumentParser((ModelArguments, DataArguments, TrainingArguments))
    model_args, data_args, training_args = parser.parse_args_into_dataclasses()
    args = {**model_args.__dict__, **data_args.__dict__, **training_args.__dict__}
    args = argparse.Namespace(**args)
    
    # latest_checkpoint = "/workspace/Qwen2.5-Coder/finetuning/sft/checkpoints-old/lr-wr-wd-bsz-maxlen/checkpoint-50"
    latest_checkpoint = find_latest_checkpoint(training_args.output_dir)

    #logging.info(args)
    if latest_checkpoint:
        print(f"Resuming from checkpoint: {latest_checkpoint}")
        model = transformers.AutoModelForCausalLM.from_pretrained(
            latest_checkpoint,
            cache_dir=training_args.cache_dir,
            attn_implementation="flash_attention_2" if model_args.use_flash_attention else None,
            trust_remote_code=True
        )
    else:
        print("Training from scratch")
        model = transformers.AutoModelForCausalLM.from_pretrained(
            model_args.model_name_or_path,
            cache_dir=training_args.cache_dir,
            attn_implementation="flash_attention_2" if model_args.use_flash_attention else None,
            trust_remote_code = True
        )
        
    if training_args.use_peft:
        peft_config = PeftConfig.from_pretrained(training_args.peft_config_path)
        model.enable_input_require_grads()
        model = get_peft_model(model, peft_config)
        model.print_trainable_parameters()
    tokenizer = transformers.AutoTokenizer.from_pretrained(
        model_args.model_name_or_path,
        pad_token = '<|endoftext|>',
        eos_token = '<|im_end|>', #<|endoftext|>
        cache_dir = None,
        model_max_length = training_args.model_max_length,
        truncation = True,
        padding_side = "right",
        trust_remote_code = True
    )

    # Add new special tokens
    special_tokens = [
            "<exec_result>", "</exec_result>", "<exec_sql>", "</exec_sql>", "<formatting>", "</formatting>"
        ]
    num_new_tokens = tokenizer.add_special_tokens({
        "additional_special_tokens": special_tokens
    })
    for token in special_tokens:
        token_id = tokenizer.convert_tokens_to_ids(token)
        print(f"Token: {token}\tID: {token_id}")
    model.resize_token_embeddings(len(tokenizer))

    input_embeddings = model.get_input_embeddings().weight.data
    output_embeddings = model.get_output_embeddings().weight.data

    input_embeddings_avg = input_embeddings[:-num_new_tokens].mean(dim=0, keepdim=True)
    output_embeddings_avg = output_embeddings[:-num_new_tokens].mean(dim=0, keepdim=True)

    input_embeddings[-num_new_tokens:] = input_embeddings_avg
    output_embeddings[-num_new_tokens:] = output_embeddings_avg

    with torch.no_grad():
        mean_embedding = model.model.embed_tokens.weight[:-num_new_tokens].mean(0)
        model.model.embed_tokens.weight[-num_new_tokens:] = mean_embedding.unsqueeze(0).expand(num_new_tokens, -1)

    data_module = make_supervised_data_module(tokenizer=tokenizer, args=args)
    trainer = CustomTrainer(
        model=model, 
        tokenizer=tokenizer, 
        args=training_args, 
        **data_module, 
        callbacks=[LoggingCallback, SaveModelCallback]
    )
    trainer.train(resume_from_checkpoint=latest_checkpoint)
    trainer.save_state()
    trainer.save_model(output_dir=training_args.output_dir)

if __name__ == "__main__":
    train()
