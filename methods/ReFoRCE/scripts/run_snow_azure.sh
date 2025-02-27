#!/bin/bash
set -e

# Set up
python spider_agent_setup_snow.py
# Reconstruct data
python reconstruct_data.py --example_folder examples
# Run
python run_vote.py --test_path examples --model o1-preview --understanding_model o1-preview --output_path output/o1-preview-snow-log --azure --num_processes 3 --task snow
# Evaluation
python get_metadata.py --result_path output/o1-preview-snow-log --output_path output/o1-preview-snow
cd ../../spider2-snow/evaluation_suite
python evaluate.py --mode exec_result --result_dir ../../methods/spider-self-refine/output/o1-preview-snow