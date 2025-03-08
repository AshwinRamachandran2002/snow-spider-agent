import os
import torch
import pickle
import transformers
from tqdm import tqdm
from typing import Optional
from dataclasses import dataclass, field
from execute_sql import exec_sql

def load_model():
    """Load the model from the specified checkpoint."""
    model = None
    model = transformers.AutoModelForCausalLM.from_pretrained(
        # "Qwen/Qwen2.5-Coder-3B-Instruct",
        "/workspace/Qwen2.5-Coder/finetuning/sft/checkpoints_syn_gen_func_call/lr-wr-wd-bsz-maxlen/checkpoint-50/",
        trust_remote_code=True
    ).to("cuda")
    tokenizer = transformers.AutoTokenizer.from_pretrained(
        "Qwen/Qwen2.5-Coder-3B-Instruct",
        pad_token='<|endoftext|>',
        eos_token='<|im_end|>',
        model_max_length=10240,
        padding_side="right",
        trust_remote_code=True
    )
    tokenizer.add_special_tokens({"additional_special_tokens": ["<|im_end|>", "<|im_start|>"]})
    return model, tokenizer


def run_inference(model, tokenizer, dataset):
    """Run inference on the dataset."""
    model.eval()
    results = []
    with torch.no_grad():
        for index, input_ids in tqdm(enumerate(dataset)):
            print("Running", index)
            # instance = dataset[index]
            # input_ids = instance['input_ids']
            full_text = tokenizer.decode(input_ids)

            full_text = "\n\n".join(full_text.split("\n\n")[:-1]) + "\n\nTask: " + full_text.split("\n\n")[-1]
            system_message = "You are a data scientist proficient in database, SQL and DBT Project. You may use <exec_sql> tags to execute SQL functions. Execution results will be returned in <exec_result> tags. Use this tool to investigate the schema before writing the final SQL"

            full_text = f"<|im_start|>system\n{system_message}<|im_end|>" + full_text.split("<|im_start|>user")[1]
            question_text = full_text + "<|im_start|>assistant"
            # question_text = full_text.split("<|im_start|>assistant")[0] + "<|im_start|>assistant"
            question_text = question_text.split("<|im_end|>\n<|im_start|>assistant")[0] + "Be as descriptive as possible in your thought. Always keep your thought more than 50 words." + "<|im_end|>\n<|im_start|>assistant"

            sqls = []
            for j in tqdm(range(4)):
                print("Main index", j)
                sql_index = 0
                question_text = """
                <|im_start|>think
First, I will decide what the output should look like.
<formatting>
csv
City,Class,Subclass,Total_Surface_Area_Sq_M,Number_of_Buildings
Amsterdam,class1:str,subclass1:str,total_surface_area1:float,num_buildings1:int
Amsterdam,class2:str,subclass2:str,total_surface_area2:float,num_buildings2:int
...
Rotterdam,class1:str,subclass1:str,total_surface_area1:float,num_buildings1:int
Rotterdam,class2:str,subclass2:str,total_surface_area2:float,num_buildings2:int
...
 
</formatting>
Let me now investigate the schema given.
 
**Relevant Columns and Potential Usage:**
 
From `NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING`:
- `"CLASS"`: to get the building class.
- `"SUBCLASS"`: to get the building subclass.
- `"SURFACE_AREA_SQ_M"`: to obtain the surface area of buildings.
- `"GEO_CORDINATES"`: to determine the location of buildings.
- `"CONTAINS_ADDR_POSTCODE"`: may be used to identify buildings in specific cities based on postal codes.
- `"BUILDING_LOCATION"`: potential location information of buildings.
- `"NAMES"`: may contain names associated with the building.
 
From `NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE`:
- `"ADMIN_LEVEL"`: to filter administrative areas at the city level.
- `"NAMES"`: to identify administrative areas named "Amsterdam" or "Rotterdam".
- `"GEO_CORDINATES"`: to get the geographical boundaries of cities.
 
**Potential Conditions:**
- Filter buildings located within the administrative boundaries of Amsterdam and Rotterdam.
- Use postal codes or location names to identify buildings in the two cities.
- Perform spatial joins using `"GEO_CORDINATES"` to match buildings with city areas.
 
---
 
<exec_sql>
-- Query 1: Get distinct building classes.
SELECT DISTINCT "CLASS"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
LIMIT 100;
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
CLASS
historic
general
education
commercial
religious
damaged
entertainment
agriculture
</exec_result>
 
 
<exec_sql>
-- Query 2: Get distinct building subclasses.
SELECT DISTINCT "SUBCLASS"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
LIMIT 100;
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
SUBCLASS
seafood
stationery
funeral_hall
antiques
bakery
gift
interior_decoration
beauty
</exec_result>
 
 
<exec_sql>
-- Query 3: Get distinct administrative levels.
SELECT DISTINCT "ADMIN_LEVEL"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
LIMIT 100;
</exec_sql>
<exec_result>
 
ADMIN_LEVEL
""
3
4
2
12
8
10
</exec_result>
 
 
<exec_sql>
-- Query 4: Get administrative area names and IDs at city level.
SELECT t."ID", t."ADMIN_LEVEL", f.value::STRING AS "ADMIN_NAME"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE t,
     LATERAL FLATTEN(input => t."NAMES") f
WHERE t."ADMIN_LEVEL" = '8'
LIMIT 100;
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
ID,ADMIN_LEVEL,ADMIN_NAME
r384840@25,8,Dantumadiel
r444099@11,8,Zoetermeer
r160999@21,8,Hellendoorn
r419211@7,8,Houten
r414748@21,8,Dinkelland
r47439@31,8,Ooststellingwerf
r416306@16,8,Heerde
r9172182@3,8,Molenlanden
</exec_result>
 
 
<exec_sql>
-- Query 5: Find administrative areas named 'Amsterdam'.
SELECT t."ID", t."ADMIN_LEVEL", f.value::STRING AS "ADMIN_NAME"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE t,
     LATERAL FLATTEN(input => t."NAMES") f
WHERE f.value::STRING ILIKE '%Amsterdam%'
LIMIT 100;
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
ID,ADMIN_LEVEL,ADMIN_NAME
r1423428@6,10,Nieuw-Amsterdam
r47811@69,8,Amsterdam
r47811@69,8,Amsterdam
r47811@69,8,Amsterdam
r47811@69,8,Amsterdam
r47811@69,8,Amsterdam
r47811@69,8,Amsterdam
r271110@45,10,Amsterdam
</exec_result>
 
 
<exec_sql>
-- Query 6: Find administrative areas named 'Rotterdam'.
SELECT t."ID", t."ADMIN_LEVEL", f.value::STRING AS "ADMIN_NAME"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE t,
     LATERAL FLATTEN(input => t."NAMES") f
WHERE f.value::STRING ILIKE '%Rotterdam%'
LIMIT 100;
</exec_sql>
<exec_result>
 
ID,ADMIN_LEVEL,ADMIN_NAME
r1411101@51,10,Rotterdam
r1411101@51,10,Rotterdam
r1379535@10,10,Rotterdam-Albrandswaard
r324431@56,8,Rotterdam
r324431@56,8,Rotterdam
</exec_result>
 
 
<exec_sql>
-- Query 7: Get building IDs and their locations.
SELECT "ID", "GEO_CORDINATES"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
LIMIT 100;
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
Too long, hard cut:
ID,GEO_CORDINATES
w283616314@1,"{
  ""coordinates"": [
    [
      [
        5.5651528,
        51.4290747
      ],
</exec_result>
 
 
<exec_sql>
-- Corrected Query: Get buildings with any non-null postal codes
SELECT *
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE "CONTAINS_ADDR_POSTCODE" IS NOT NULL
LIMIT 100;
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
Too long, hard cut:
ID,CLASS,SUBCLASS,QUADKEY,NAMES,ORIGINAL_SOURCE_TAGS,GEO_CORDINATES,AMENITY,BUILDING_LOCATION,SHOP,CONTAINS_ADDR_POSTCODE,HEIGHT_M,WIKIDATA,LANDUSE,BUILDING_LEVELS,TOURISM,CONTAINS_ADDRESSES,LAYER,MIN_HEIGHT_M,SURFACE_AREA_SQ_M,BUILDING,CONTAINS_ADDR_STREET
w279234831@1,industrial,industrial,120202111030131,{},"{
  ""building"": ""industrial"",
  ""ref:bag"": ""34100000077575"",
  ""source"": ""BAG"",
  ""source:date"": ""2014-03-24"",
  ""start_date"": ""2000""
}","{
</exec_result>
 
 
<exec_sql>
-- Corrected Query 9: Get buildings with any non-null postal codes
SELECT *
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE "CONTAINS_ADDR_POSTCODE" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
Too long, hard cut:
ID,CLASS,SUBCLASS,QUADKEY,NAMES,ORIGINAL_SOURCE_TAGS,GEO_CORDINATES,AMENITY,BUILDING_LOCATION,SHOP,CONTAINS_ADDR_POSTCODE,HEIGHT_M,WIKIDATA,LANDUSE,BUILDING_LEVELS,TOURISM,CONTAINS_ADDRESSES,LAYER,MIN_HEIGHT_M,SURFACE_AREA_SQ_M,BUILDING,CONTAINS_ADDR_STREET
w261932376@1,residential,dwelling,120203000310120,{},"{
  ""building"": ""house"",
  ""ref:bag"": ""150100000028007"",
  ""source"": ""BAG"",
  ""source:date"": ""2014-02-11"",
  ""start_date"": ""1982""
}","{
</exec_result>
 
 
<exec_sql>
-- Corrected Query 10: Check non-null surface area values
SELECT "SURFACE_AREA_SQ_M"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE "SURFACE_AREA_SQ_M" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
SURFACE_AREA_SQ_M
169.88
25.79
14.54
53.32
46.98
478.69
160.08
7.16
</exec_result>
 
 
<exec_sql>
-- Corrected Query 11: Convert surface area to numeric where possible
SELECT "ID", TRY_TO_NUMBER("SURFACE_AREA_SQ_M") AS "SURFACE_AREA"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE TRY_TO_NUMBER("SURFACE_AREA_SQ_M") IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
ID,SURFACE_AREA
w272472700@1,27
w521288344@1,49
w271652445@1,51
w283576762@1,52
w955297978@2,930
w261865939@2,62
w280084470@1,44
w302336620@1,19
</exec_result>
 
 
<exec_sql>
-- Corrected Query 12: Get building classes and subclasses with IDs where class is not null
SELECT "ID", "CLASS", "SUBCLASS"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE "CLASS" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
ID,CLASS,SUBCLASS
w283616314@1,general,building
w278395159@1,general,building
w271987002@1,general,building
w665634743@3,residential,dwelling
w283772524@1,residential,dwelling
w278481204@2,general,building
w275757542@2,general,building
w276358010@1,general,building
</exec_result>
 
 
<exec_sql>
-- Corrected Query 13: Inspect building location details with non-null values
SELECT DISTINCT "BUILDING_LOCATION"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE "BUILDING_LOCATION" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
BUILDING_LOCATION
surface
indoor
112_Locatie_informatie
overground
underwater
outdoor
overhead
kiosk
</exec_result>
 
 
<exec_sql>
-- Corrected Query 14: Get names associated with buildings where NAMES is not null
SELECT t."ID", f.value::STRING AS "BUILDING_NAME"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING t,
     LATERAL FLATTEN(input => t."NAMES") f
WHERE t."NAMES" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
ID,BUILDING_NAME
w285537680@1,Brug en Bosch
w513709935@5,De Heere Regeert
w272360183@8,Tuinland Assen
w44898013@4,Zuidpark
w280087240@2,Autobedrijf Plantinga
w228896214@5,Ocarina I
w281121916@3,Courtine
w275590788@3,F/G Building
</exec_result>
 
 
<exec_sql>
-- Corrected Query 15: Get buildings where "NAMES" contains 'Amsterdam'
SELECT *
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING t,
     LATERAL FLATTEN(input => t."NAMES") f
WHERE f.value::STRING ILIKE '%Amsterdam%'
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
Too long, hard cut:
ID,CLASS,SUBCLASS,QUADKEY,NAMES,ORIGINAL_SOURCE_TAGS,GEO_CORDINATES,AMENITY,BUILDING_LOCATION,SHOP,CONTAINS_ADDR_POSTCODE,HEIGHT_M,WIKIDATA,LANDUSE,BUILDING_LEVELS,TOURISM,CONTAINS_ADDRESSES,LAYER,MIN_HEIGHT_M,SURFACE_AREA_SQ_M,BUILDING,CONTAINS_ADDR_STREET,SEQ,KEY,PATH,INDEX,VALUE,THIS
w157089326@6,general,building,120202110113333,"{
  ""local"": ""Pakhuis Amsterdam""
}","{
  ""building"": ""yes"",
  ""ref:bag"": ""363100012119104"",
  ""source"": ""BAG"",
  ""source:date"": ""2014-03-24"",
</exec_result>
 
 
<exec_sql>
-- Corrected Query 16: Get buildings where "NAMES" contains 'Rotterdam'
SELECT *
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING t,
     LATERAL FLATTEN(input => t."NAMES") f
WHERE f.value::STRING ILIKE '%Rotterdam%'
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
Too long, hard cut:
ID,CLASS,SUBCLASS,QUADKEY,NAMES,ORIGINAL_SOURCE_TAGS,GEO_CORDINATES,AMENITY,BUILDING_LOCATION,SHOP,CONTAINS_ADDR_POSTCODE,HEIGHT_M,WIKIDATA,LANDUSE,BUILDING_LEVELS,TOURISM,CONTAINS_ADDRESSES,LAYER,MIN_HEIGHT_M,SURFACE_AREA_SQ_M,BUILDING,CONTAINS_ADDR_STREET,SEQ,KEY,PATH,INDEX,VALUE,THIS
w255337543@5,general,building,120202112031200,"{
  ""local"": ""Harbour Village Rotterdam (1)""
}","{
  ""building"": ""yes"",
  ""ref:bag"": ""599100000750224"",
  ""source"": ""BAG"",
  ""source:date"": ""2013-11-26"",
</exec_result>
 
 
<exec_sql>
-- Corrected Query 17: Get buildings with their classes and surface areas where data is not null
SELECT "ID", "CLASS", "SUBCLASS", "SURFACE_AREA_SQ_M"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE "CLASS" IS NOT NULL AND "SURFACE_AREA_SQ_M" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
ID,CLASS,SUBCLASS,SURFACE_AREA_SQ_M
w272703190@1,residential,dwelling,99.65
w286588377@1,general,building,6.81
w258287674@3,residential,dwelling,91.95
w275200308@1,general,building,22.25
w273957617@1,residential,dwelling,48.44
w274999638@1,general,building,17.3
w272078461@1,residential,dwelling,94.33
w271326710@2,residential,dwelling,58.5
</exec_result>
 
 
<exec_sql>
-- Corrected Query 18: List distinct postal codes available
SELECT DISTINCT "CONTAINS_ADDR_POSTCODE"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE "CONTAINS_ADDR_POSTCODE" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
CONTAINS_ADDR_POSTCODE
"[""8161RK""]"
"[""1431DJ""]"
"[""9978TC""]"
"[""5215VE""]"
"[""1422SE""]"
"[""2613BH""]"
"[""7645AN""]"
"[""4681BK""]"
</exec_result>
 
 
<exec_sql>
-- Corrected Query 19: Get buildings with non-null surface area
SELECT "ID", "CLASS", "SUBCLASS", "SURFACE_AREA_SQ_M"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING
WHERE "SURFACE_AREA_SQ_M" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
ID,CLASS,SUBCLASS,SURFACE_AREA_SQ_M
w276240258@1,residential,dwelling,58.48
w254192043@1,residential,dwelling,73.9
w283345500@1,general,building,23.89
w1123387698@1,general,building,11.25
w282140039@1,residential,dwelling,272.65
w271663302@1,residential,dwelling,43.4
w281664475@1,residential,dwelling,108.68
w270713648@2,residential,dwelling,91.2
</exec_result>
 
 
<exec_sql>
-- Corrected Query 20: Get administrative areas with their geographical coordinates where GEO_CORDINATES is not null
SELECT "ID", "ADMIN_LEVEL", "GEO_CORDINATES"
FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
WHERE "GEO_CORDINATES" IS NOT NULL
LIMIT 100
</exec_sql>
<exec_result>
Printing only the first 10 rows of the output:
 
Too long, hard cut:
ID,ADMIN_LEVEL,GEO_CORDINATES
w1198581681@1,10,"{
  ""coordinates"": [
    [
      5.4379723,
      51.985661
    ],
    [
</exec_result>
 
I think I now have a good understanding of the schema. Let me now generate the SQL query to solve the task.
 We will parse the "CONTAINS_ADDRESSES" JSON column to extract the city name, filter by Amsterdam and Rotterdam, then aggregate the total surface area (casting "SURFACE_AREA_SQ_M" to FLOAT) and count the buildings for each (class, subclass) combination in both cities. We will break this into multiple CTEs for clarity.
 
 
<|im_start|>SQL
WITH amsterdam_boundary AS (
    SELECT ST_UNION_AGG(t."GEO_CORDINATES") AS "GEO_CORDINATES"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE t,
         LATERAL FLATTEN(input => t."NAMES") f
    WHERE t."ADMIN_LEVEL" = '8' AND f.value::STRING ILIKE '%Amsterdam%'
),
rotterdam_boundary AS (
    SELECT ST_UNION_AGG(t."GEO_CORDINATES") AS "GEO_CORDINATES"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE t,
         LATERAL FLATTEN(input => t."NAMES") f
    WHERE t."ADMIN_LEVEL" = '8' AND f.value::STRING ILIKE '%Rotterdam%'
),
amsterdam_buildings AS (
    SELECT 'Amsterdam' AS "City",
           b."CLASS",
           b."SUBCLASS",
           TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M") AS "SURFACE_AREA"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b, amsterdam_boundary a
    WHERE ST_INTERSECTS(b."GEO_CORDINATES", a."GEO_CORDINATES")
      AND TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M") IS NOT NULL
),
rotterdam_buildings AS (
    SELECT 'Rotterdam' AS "City",
           b."CLASS",
           b."SUBCLASS",
           TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M") AS "SURFACE_AREA"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b, rotterdam_boundary r
    WHERE ST_INTERSECTS(b."GEO_CORDINATES", r."GEO_CORDINATES")
      AND TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M") IS NOT NULL
)
SELECT "City", "CLASS", "SUBCLASS",
       ROUND(SUM("SURFACE_AREA"), 4) AS "Total_Surface_Area_Sq_M",
       COUNT(*) AS "Number_of_Buildings"
FROM (
    SELECT * FROM amsterdam_buildings
    UNION ALL
    SELECT * FROM rotterdam_buildings
) AS all_buildings
GROUP BY "City", "CLASS", "SUBCLASS"
ORDER BY "City", "CLASS", "SUBCLASS";
<|im_end|>Wait..The above approach is incorrect.\n<|im_start|>think
                """
                while sql_index==0:
                    inputs = tokenizer(question_text, return_tensors="pt", truncation=True, padding=True).to(model.device)
                    output_ids = model.generate(**inputs, max_new_tokens=3000)
                    output_text = tokenizer.decode(output_ids[0])
                    print("Output", output_text)
                    print("SQL index", sql_index)
                    splits = output_text.split("<exec_sql>")[1:]
                    if len(splits) == (sql_index + 1):
                        break
                    sql_query = splits[sql_index+1].split("</exec_sql>")[0]
                    exec_output = "Printing only top 10 results.\n" + "\n".join(exec_sql(sql_query)[:10])
                    print("EXEC output", exec_output)
                    question_text = "<exec_result>".join(output_text.split("<exec_result>")[:sql_index+2]) + "<exec_result>\n" + exec_output + "</exec_result>\n"
                    sql_index += 1
                    input()
                print("Final SQL", output_text.split("<|im_start|>SQL")[-1].split("<|im_end|>")[0])
                sqls.append(output_text.split("<|im_start|>SQL")[-1].split("<|im_end|>")[0])
                question_text = "<|im_end|>".join(output_text.split("<|im_end|>")[:-1]) + "Wait..The above approach is incorrect.\n<|im_start|>think"

            with open(f"results_func_call/{index}.pkl", "wb") as f:
                pickle.dump({
                    "question_text": question_text,
                    "sqls": sqls,
                    "output_text": output_text
                }, f)

    return results

def main():
    import numpy as np
    data_path = "processed/val_gen.jsonl.npy"
    data = np.load(data_path, allow_pickle=True)

    datas_sorted = []
    for index, instance in tqdm(enumerate(data)):
        instance = data[index]
        if "input_ids" in instance:
            datas_sorted.append(instance["input_ids"])

    # sort based on length
    datas_sorted = sorted(datas_sorted, key=lambda x: len(x))    
    
    model, tokenizer = load_model()
    results = run_inference(model, tokenizer, datas_sorted)

if __name__ == "__main__":
    main()
