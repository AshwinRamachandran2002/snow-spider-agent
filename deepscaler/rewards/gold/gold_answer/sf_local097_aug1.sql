-- Task: Find the earliest and latest movie release years in our data.
SELECT 
  MIN(TO_NUMBER(REGEXP_REPLACE("year", '[^0-9]', ''))) AS "Earliest_Year",
  MAX(TO_NUMBER(REGEXP_REPLACE("year", '[^0-9]', ''))) AS "Latest_Year"
FROM "DB_IMDB"."DB_IMDB"."MOVIE"
WHERE REGEXP_REPLACE("year", '[^0-9]', '') <> '';