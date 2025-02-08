import os
import random
from ..chat import GPTChat
import argparse
random.seed(42)

def main(args):
    snow_gold_sql_path = "../../../spider2-snow/evaluation_suite/gold/sql"
    lite_gold_sql_path = "../../../spider2-lite/evaluation_suite/gold/sql"

    snow_gold_sql_ids = [i.replace(".sql", "") for i in os.listdir(snow_gold_sql_path)]
    lite_gold_sql_ids = [i.replace(".sql", "") for i in os.listdir(lite_gold_sql_path)]
    gold_list = list(set(snow_gold_sql_ids) | set(lite_gold_sql_ids))
    gold_sampled = random.sample(gold_list, 150)

    snow_easier_ids = ['sf001', 'sf014', 'sf044', 'sf_bq005', 'sf_bq006', 'sf_bq010', 'sf_bq017', 'sf_bq018', 'sf_bq021', 'sf_bq025', 'sf_bq032', 'sf_bq033', 'sf_bq034', 'sf_bq035', 'sf_bq042', 'sf_bq056', 'sf_bq059', 'sf_bq060', 'sf_bq061', 'sf_bq066', 'sf_bq076', 'sf_bq077', 'sf_bq078', 'sf_bq081', 'sf_bq085', 'sf_bq088', 'sf_bq090', 'sf_bq091', 'sf_bq096', 'sf_bq097', 'sf_bq103', 'sf_bq109', 'sf_bq113', 'sf_bq115', 'sf_bq121', 'sf_bq126', 'sf_bq130', 'sf_bq143', 'sf_bq151', 'sf_bq158', 'sf_bq161', 'sf_bq171', 'sf_bq172', 'sf_bq176', 'sf_bq210', 'sf_bq211', 'sf_bq213', 'sf_bq214', 'sf_bq216', 'sf_bq218', 'sf_bq219', 'sf_bq223', 'sf_bq224', 'sf_bq227', 'sf_bq228', 'sf_bq232', 'sf_bq252', 'sf_bq255', 'sf_bq264', 'sf_bq270', 'sf_bq279', 'sf_bq280', 'sf_bq281', 'sf_bq282', 'sf_bq284', 'sf_bq285', 'sf_bq286', 'sf_bq289', 'sf_bq300', 'sf_bq302', 'sf_bq303', 'sf_bq308', 'sf_bq309', 'sf_bq310', 'sf_bq321', 'sf_bq327', 'sf_bq328', 'sf_bq330', 'sf_bq334', 'sf_bq341', 'sf_bq345', 'sf_bq349', 'sf_bq350', 'sf_bq352', 'sf_bq355', 'sf_bq357', 'sf_bq359', 'sf_bq361', 'sf_bq362', 'sf_bq375', 'sf_bq377', 'sf_bq379', 'sf_bq389', 'sf_bq392', 'sf_bq394', 'sf_bq396', 'sf_bq399', 'sf_bq407', 'sf_bq414', 'sf_bq419', 'sf_bq444', 'sf_ga001', 'sf_ga002', 'sf_ga003', 'sf_ga004', 'sf_ga010', 'sf_ga020', 'sf_local008', 'sf_local009', 'sf_local019', 'sf_local021', 'sf_local022', 'sf_local023', 'sf_local029', 'sf_local031', 'sf_local038', 'sf_local039', 'sf_local041', 'sf_local054', 'sf_local056', 'sf_local058', 'sf_local065', 'sf_local067', 'sf_local071', 'sf_local072', 'sf_local074', 'sf_local075', 'sf_local078', 'sf_local097', 'sf_local099', 'sf_local141', 'sf_local163', 'sf_local197', 'sf_local198', 'sf_local199', 'sf_local201', 'sf_local202', 'sf_local210', 'sf_local218', 'sf_local221', 'sf_local244', 'sf_local274', 'sf_local284', 'sf_local309', 'sf_local311', 'sf_local329']
    lite_easier_ids = ['bq002', 'bq009', 'bq010', 'bq018', 'bq021', 'bq025', 'bq032', 'bq034', 'bq035', 'bq042', 'bq060', 'bq061', 'bq066', 'bq076', 'bq077', 'bq078', 'bq085', 'bq090', 'bq097', 'bq105', 'bq109', 'bq113', 'bq115', 'bq123', 'bq126', 'bq130', 'bq161', 'bq172', 'bq204', 'bq228', 'bq232', 'bq235', 'bq279', 'bq280', 'bq281', 'bq282', 'bq284', 'bq285', 'bq286', 'bq300', 'bq301', 'bq302', 'bq303', 'bq310', 'bq327', 'bq328', 'bq330', 'bq352', 'bq355', 'bq357', 'bq362', 'bq374', 'bq389', 'bq392', 'bq394', 'bq396', 'bq414', 'ga001', 'ga002', 'ga003', 'ga004', 'ga007', 'ga010', 'ga011', 'ga017', 'ga025', 'local004', 'local017', 'local019', 'local022', 'local023', 'local029', 'local031', 'local038', 'local039', 'local041', 'local054', 'local056', 'local058', 'local059', 'local065', 'local071', 'local072', 'local074', 'local075', 'local078', 'local097', 'local099', 'local141', 'local152', 'local163', 'local195', 'local198', 'local199', 'local202', 'local210', 'local218', 'local221', 'local229', 'local284', 'local301', 'local309', 'local311', 'local329', 'sf001', 'sf014', 'sf044', 'sf_bq005', 'sf_bq017', 'sf_bq033', 'sf_bq056', 'sf_bq091', 'sf_bq158', 'sf_bq171', 'sf_bq176', 'sf_bq210', 'sf_bq211', 'sf_bq213', 'sf_bq214', 'sf_bq216', 'sf_bq219', 'sf_bq223', 'sf_bq224', 'sf_bq252', 'sf_bq255', 'sf_bq264', 'sf_bq289', 'sf_bq321', 'sf_bq334', 'sf_bq341', 'sf_bq345', 'sf_bq349', 'sf_bq359', 'sf_bq361', 'sf_bq375', 'sf_bq377', 'sf_bq444']
    easier_list = list(set(snow_easier_ids) | set(lite_easier_ids))
    easier_sampled = random.sample(easier_list, 150)

    combined_list = list(set(gold_sampled) | set(easier_sampled))
    print(f"Spider2.0 training data number: {len(combined_list)}")

    train_dict = {}
    test_dict = {}
    # if args.data_argumentaion:


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--model_api', type=str, default="o1-preview")
    parser.add_argument('--azure', action="store_true")
    parser.add_argument('--temperature', type=float, default=0)
    parser.add_argument('--data_argumentaion', action="store_true")
    args = parser.parse_args()
    main(args)