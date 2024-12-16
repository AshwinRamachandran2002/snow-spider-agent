#!/bin/bash
set -e

# Set up
python spider_agent_setup_snow.py
# Reconstruct data
python reconstruct_data.py --example_folder examples
# Run
export OPENAI_API_KEY=YOUR_API_KEY
python run.py --test_path examples --model o1-preview-test1 --output_path output/o1-preview-test1-log
# Evaluation
python get_metadata.py --result_path output/o1-preview-test1-log --output_path output/o1-preview-test1
cd ../../spider2-snow/evaluation_suite
python evaluate.py --mode exec_result --result_dir ../../methods/spider-self-refine/output/o1-preview-test1