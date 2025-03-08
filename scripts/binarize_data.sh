export PATH=/path/to/miniconda3/envs/qwen/bin:$PATH;
INPUT_PATH=${1}
OUTPUT_PATH=${2}
TOKENIZER_PATH=${3}
INPUT_PATH=${INPUT_PATH:-"./raw/syn_gen_func_call_dialect.jsonl"}
OUTPUT_PATH=${OUTPUT_PATH:-"./processed/syn_gen_func_call_dialect.jsonl"}
TOKENIZER_PATH=${TOKENIZER_PATH:-"Qwen/Qwen2.5-Coder-3B-Instruct"}
python binarize_data.py -input_path ${INPUT_PATH} -output_path ${OUTPUT_PATH} -workers 64 -tokenizer_path ${TOKENIZER_PATH}