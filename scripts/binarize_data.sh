export PATH=/path/to/miniconda3/envs/sft_env/bin:$PATH;
INPUT_PATH=$1
OUTPUT_PATH=$2
TOKENIZER_PATH=$3
python binarize_data.py -input_path ${INPUT_PATH} -output_path ${OUTPUT_PATH} -workers 64 -tokenizer_path ${TOKENIZER_PATH}