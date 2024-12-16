import os
import argparse

# folder_path = "./output/test"
# folder_path = "/root/repo/Spider2-dev/spider2/evaluation_suite/gold"
# folder_path = "examples"
def rename(folder_path):
    for filename in os.listdir(folder_path):
        if filename.startswith("sf_"):
            old_file = os.path.join(folder_path, filename)
            new_file = os.path.join(folder_path, ''.join(filename.split('_')[1:]))
            os.rename(old_file, new_file)

# for filename in os.listdir(folder_path):
#     if not filename.startswith("sf_"):
#         old_file = os.path.join(folder_path, filename)
#         new_file = os.path.join(folder_path, 'sf_' + filename)
#         os.rename(old_file, new_file)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--folder_path', type=str, default="./output/gpt-4o-test1")
    args = parser.parse_args()

    rename(args.folder_path)