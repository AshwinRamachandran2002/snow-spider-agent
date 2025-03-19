export PATH=/path/to/miniconda3/envs/qwen/bin:$PATH;
INPUT_PATH="raw/bird_sft.jsonl"
OUTPUT_PATH="processed/bird_sft.jsonl"
TOKENIZER_PATH="../../end2end/snow-spider-agent/models/Qwen2.5-Coder-7B-Instruct/"
python binarize_data.py -input_path ${INPUT_PATH} -output_path ${OUTPUT_PATH} -workers 64 -tokenizer_path ${TOKENIZER_PATH}