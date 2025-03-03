import pandas as pd

train_file = "deepscaler/data/processed/val_data.parquet"
df = pd.read_parquet(train_file)

new_content = [{"role": "system", "content": "You are a data scientist proficient in database, SQL and DBT Project. You may use <exec_sql> tags to execute SQL functions. Execution results will be returned in <exec_result> tags. Use this tool to investigate the schema before writing the final SQL"}, {"role": "user", "content": "Information about the Database:\n\n--------------------------------------------------\nTable: BBC.BBC_NEWS.FULLTEXT\n\nColumn:\"title\", (TEXT), (e.g., ,  Global blogger action day called,  Global digital divide 'narrowing',  Satellite mapping aids Darfur relief,  DVD copy protection strengthened,  Text message record smashed again)\nColumn:\"filename\", (TEXT), (e.g., ,  bbc/tech/016.txt,  bbc/tech/033.txt,  bbc/tech/056.txt,  bbc/tech/086.txt,  bbc/tech/223.txt)\nColumn:\"category\", (TEXT), (e.g., ,  tech,  sport,  business,  politics,  entertainment)\nColumn:\"body\", (TEXT), (e.g., ,  The global web blog community is being called into action to lend support to two imprisoned Iranian ...)\n--------------------------------------------------\nExternal knowledge that might be helpful:\nNone\n\n\nThe table structure information is ({database name: {schema name: {table name}}}): \n{'BBC': {'BBC_NEWS': ['FULLTEXT']}}\n\n\nTask: Can you provide a breakdown of the total number of articles into different categories and the percentage of those articles that mention \"education\" within each category from the BBC News?\n\n\n"}]

for i in range(len(df.iloc[:])):
    df.iloc[i]['prompt'] = new_content

output_file = "deepscaler/data/processed/val_data.parquet"
df.to_parquet(output_file, index=False)