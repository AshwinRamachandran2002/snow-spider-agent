from huggingface_hub import hf_hub_download

file_path = hf_hub_download(
    repo_id="xxxbrem/OmniSQL-BIRD",
    filename="train_bird.json",
    repo_type="dataset",
    local_dir="./data/train",
    local_dir_use_symlinks=False
)

file_path = hf_hub_download(
    repo_id="xxxbrem/OmniSQL-BIRD",
    filename="dev_bird.json",
    repo_type="dataset",
    local_dir="./data/dev",
    local_dir_use_symlinks=False
)

