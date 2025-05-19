INPUT_PATH=$1
OUTPUT_PATH=$2
TOKENIZER_PATH=$3
python binarize_data_r1.py --input_path ${INPUT_PATH} --output_path ${OUTPUT_PATH} --workers 64 --tokenizer_path ${TOKENIZER_PATH}