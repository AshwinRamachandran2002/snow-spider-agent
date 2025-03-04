from transformers import AutoModel
import torch

# Define model paths
original_model_path = "models/DeepSeek-R1-Distill-Qwen-7B"
trained_model_path = "checkpoints/deepscaler/deepscaler-7b-4n-debug/actor/global_step_100"

# Load models
original_model = AutoModel.from_pretrained(original_model_path)
trained_model = AutoModel.from_pretrained(trained_model_path)

# Define thresholds
thresholds = [1e-3, 1e-4, 1e-5, 1e-6]
unchanged_counts = {thresh: 0 for thresh in thresholds}
total_count = 0

# Compare weights
for (orig_name, orig_param), (train_name, train_param) in zip(original_model.state_dict().items(), trained_model.state_dict().items()):
    assert orig_name == train_name, f"Mismatch in layer names: {orig_name} vs {train_name}"

    # Ensure same shape
    assert orig_param.shape == train_param.shape, f"Shape mismatch in {orig_name}"

    # Compute absolute differences
    diff = torch.abs(orig_param - train_param)
    
    # Count unchanged weights under different thresholds
    for thresh in thresholds:
        unchanged_counts[thresh] += (diff < thresh).sum().item()
    
    total_count += orig_param.numel()

# Print results
print(f"Total number of parameters: {total_count}")
for thresh in thresholds:
    percent = (unchanged_counts[thresh] / total_count) * 100
    print(f"Percentage of weights with |Δw| < {thresh}: {percent:.2f}%")
