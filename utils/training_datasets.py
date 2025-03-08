import torch
from torch.utils.data import Dataset
from typing import Dict
import transformers
import logging
import numpy as np
import utils
logging.basicConfig(level=logging.DEBUG)  



class SupervisedDataset(Dataset):
    """Dataset for supervised fine-tuning."""

    def __init__(self, data_path: str, tokenizer: transformers.PreTrainedTokenizer, args):
        super(SupervisedDataset, self).__init__()
        logging.warning("Loading data...")
        if data_path.endswith(".npy"):
            self.input_ids = np.load(data_path, allow_pickle=True)
        else:
            self.input_ids = utils.read_jsonl_file(data_path)
        original_data_num = len(self.input_ids)
        logging.info("Completely Loading tokenized sentences...")
        def truncate(sentence):
            return torch.tensor(sentence[:args.model_max_length] + [tokenizer.eos_token_id] if len(sentence) > args.model_max_length else sentence, dtype=torch.long)
        if args.truncate_source:
            self.labels = [truncate(example["label"]) for example in self.input_ids]
            self.input_ids = [truncate(example["input_ids"]) for example in self.input_ids]
        else:
            self.labels = [torch.tensor(example["label"], dtype=torch.long) for example in self.input_ids if len(example["input_ids"]) < args.model_max_length]
            self.input_ids = [torch.tensor(example["input_ids"], dtype=torch.long) for example in self.input_ids if len(example["input_ids"]) < args.model_max_length]
        print(f"Samples: {original_data_num} -> {len(self.input_ids)}")


    def __len__(self):
        return len(self.input_ids)

    def __getitem__(self, i) -> Dict[str, torch.Tensor]:        
        return dict(input_ids=self.input_ids[i], labels=self.labels[i])


if __name__ == "__main__":
    from torch.utils.data import DataLoader
    dataset = BufferedJsonlDataset(
        data_path="path/to/your/large.jsonl",
        buffer_size=1000,
        seed=42,
        shuffle=True
    )
    dataloader = DataLoader(
        dataset,
        batch_size=32,
        num_workers=4, 
        pin_memory=True 
    )
    for batch in dataloader:
        pass