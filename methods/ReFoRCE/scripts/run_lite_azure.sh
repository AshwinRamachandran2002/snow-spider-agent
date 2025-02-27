#!/bin/bash
set -e

# Set up
gdown 'https://drive.google.com/uc?id=1coEVsCZq-Xvj9p2TnhBFoFTsY-UoYGmG' -O ../../spider2-lite/resource/
rm -rf ../../spider2-lite/resource/databases/spider2-localdb
mkdir -p ../../spider2-lite/resource/databases/spider2-localdb
unzip ../../spider2-lite/resource/local_sqlite.zip -d ../../spider2-lite/resource/databases/spider2-localdb
python spider_agent_setup_lite.py
# Reconstruct data
python reconstruct_data.py --example_folder examples_lite
# Run
python run_vote.py --test_path examples_lite --model o1-preview --understanding_model o1-preview --output_path output/o1-preview-lite-log --azure --num_processes 3 --task lite
# Evaluation
python get_metadata.py --result_path output/o1-preview-lite-log --output_path output/o1-preview-lite
cd ../../spider2-lite/evaluation_suite
python evaluate.py --mode exec_result --result_dir ../../methods/spider-self-refine/output/o1-preview-lite