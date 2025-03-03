WITH min_max AS (
  SELECT 
    MIN(TO_NUMBER(REGEXP_REPLACE("year", '[^0-9]', ''))) AS min_year,
    MAX(TO_NUMBER(REGEXP_REPLACE("year", '[^0-9]', ''))) AS max_year
  FROM "DB_IMDB"."DB_IMDB"."MOVIE"
  WHERE REGEXP_REPLACE("year", '[^0-9]', '') <> ''
),
seq AS (
  SELECT ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS n
  FROM TABLE(GENERATOR(ROWCOUNT => 1000))
),
start_years AS (
  SELECT min_max.min_year + seq.n AS "Start_Year"
  FROM seq, min_max
  WHERE min_max.min_year + seq.n <= min_max.max_year - 9
)
SELECT sy."Start_Year", COUNT(m."MID") AS "Total_Films"
FROM start_years sy
LEFT JOIN "DB_IMDB"."DB_IMDB"."MOVIE" m
  ON REGEXP_REPLACE(m."year", '[^0-9]', '') <> ''
     AND TO_NUMBER(REGEXP_REPLACE(m."year", '[^0-9]', '')) BETWEEN sy."Start_Year" AND sy."Start_Year" + 9
GROUP BY sy."Start_Year"
ORDER BY "Total_Films" DESC NULLS LAST, sy."Start_Year" ASC
LIMIT 1;