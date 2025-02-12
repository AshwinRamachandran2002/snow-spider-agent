## Training Data


### Spider1.0 & BIRD Setup:
Find Spider dataset in: https://yale-lily.github.io/spider. 
```
gdown 1403EGqzIDoHMdQF4c9Bkyl7dZLZ5Wt6J
unzip spider_data.zip
```
Place in `Spider` folder like:
```
- 📁 Spider/
    - 📁 spider_data/
        - 📁 databse/
        - 📁 test_databse/
        - 📄 dev.json
        - 📄 test.json
        - 📄 train_others.json
        - 📄 train_spider.json
```
Find BIRD dataset in: https://bird-bench.github.io/. 
```
wget https://bird-bench.oss-cn-beijing.aliyuncs.com/train.zip
wget https://bird-bench.oss-cn-beijing.aliyuncs.com/dev.zip
unzip train.zip
unzip dev.zip
```
Place in `BIRD` folder like:
```
- 📁 BIRD/
    - 📁 dev/
        - 📁 dev_databses/
        - 📄 dev.json
    - 📁 train/
        - 📁 train_databses/
        - 📄 train.json
```
<!-- Run:
```
cd data
python get_dataset.py
``` -->
### Spider2.0 Setup:
Setup Snow:
```
python spider_agent_setup_snow.py
```
Setup Lite:
```
gdown 'https://drive.google.com/uc?id=1coEVsCZq-Xvj9p2TnhBFoFTsY-UoYGmG' -O ../../spider2-lite/resource/
rm -rf ../../spider2-lite/resource/databases/spider2-localdb
mkdir -p ../../spider2-lite/resource/databases/spider2-localdb
unzip ../../spider2-lite/resource/local_sqlite.zip -d ../../spider2-lite/resource/databases/spider2-localdb
python spider_agent_setup_lite.py
```
Reconstruct Dataset:
```
python reconstruct_data.py --example_folder data/Spider2.0_snow
python reconstruct_data.py --example_folder data/Spider2.0_lite
```
### Get Training and Testing Data:
Export GPT or Azure API:
```
export OPENAI_API_KEY=YOUR_API_KEY
export AZURE_ENDPOIONT=YOUR_AZURE_ENDPOIONT
export AZURE_OPENAI_KEY=YOUR_AZURE_API_KEY
```
Data Preprocessing:
```
python data_preprocessing.py --model_api o1-preview --azure --schema_linking --data_augmentaion
```