import os
import json
import shutil
import argparse

def save_to_jsonl(folder_names, file_path):
    with open(file_path, 'w', encoding='utf-8') as file:
        for name in folder_names:
            line = {'instance_id': name, "answer_type": "file", "answer_or_path": f"result.csv"}
            file.write(json.dumps(line, ensure_ascii=False) + '\n')

def get_csv_from_dic(folder_names, output_dic):
    for sql in folder_names:
        name = sql+"/result.csv"
        if os.path.exists(directory + '/' + name):
            path_csv = os.path.join(directory, name)
            shutil.copy(path_csv, os.path.join(output_dic, f"{sql}.csv"))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--result_path', type=str, default="output/gpt-4o-test1")
    args = parser.parse_args()

    # directory = "output/o1-preview-test1"
    directory = args.result_path
    output_dic = directory + "-csv"
    if not os.path.exists(output_dic):
        os.makedirs(output_dic)
    folder_names = [name for name in os.listdir(directory) if os.path.isdir(os.path.join(directory, name))]
    save_to_jsonl(folder_names, directory+'/results_metadata.jsonl')
    # get_csv_from_dic(folder_names, output_dic)