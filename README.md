## Setup

1. **Create a Conda Environment**
   Use the following command to create and activate a new environment for the SFT training:
   
   ```bash
   conda create -n sft_env python=3.9
   conda activate sft_env
   ```
2. **Install Dependencies**
   After activating the environment, install all required dependencies by running:
   
   ```bash
   pip install -r requirements.txt
   ```
3. **Binarize Data**
   Provide the raw data as follows:
   the raw JSONLINE file contains a JSON object (each line). Each sample should follow the following format:
   ```json
   {
        "messages":[
            {"role": "system", "content": "You are Qwen, created by Alibaba Cloud. You are a helpful assistant."},
            {"role": "user", "content": "Write a regex expression to match any letter of the alphabet"},
            {"role": "assistant", "content": "The regex expression to match any letter of the alphabet (either in uppercase or lowercase) is: \n\n```regex\n[a-zA-Z]\n```"},
            {"role": "user", "content": "How about if I only want to match uppercase letters? Can you modify the regex expression for that?"},
            {"role": "assistant", "content": "Sure, the regex expression to match any uppercase letter of the alphabet is:\n\n```regex\n[A-Z]\n```"}
       ],
       "format": "chatml"
   }
   ```
   For the SFT datasets, the raw JSONLINE file follows the following format:
   ```
   {"messages": [sample1...], "format": "chatml"}
   {"messages": [sample2...], "format": "chatml"}
   {"messages": [sample3...], "format": "chatml"}
   ```
   Binarize the raw data:
   
   ```bash
   INPUT_PATH="raw/ds_bird_trajectory.jsonl"
   OUTPUT_PATH="processed/ds_bird_trajectory.jsonl"
   TOKENIZER_PATH="../models/DeepSeek-R1-Distill-Qwen-14B"
   bash ./scripts/binarize_data.sh ${INPUT_PATH} ${OUTPUT_PATH} ${TOKENIZER_PATH}
   ```
5. **Training**
   Once the environment is ready and the model paths are configured, run the evaluation suite by executing the following script:
   
   ```bash
   DATA_PATH="processed/ds_bird_trajectory.jsonl.npy"
   PRETRAINED_MODEL="../models/DeepSeek-R1-Distill-Qwen-14B"
   OUTPUT_DIR="../ag/models/DeepSeek-R1-Distill-Qwen-14B-sft"
   sbatch ./scripts/sbatch_multi.sh ${DATA_PATH} ${PRETRAINED_MODEL} ${OUTPUT_DIR}
   ```
