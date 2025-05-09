WITH bg_2016 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11) AS tract_code,
        AVG("median_income")    AS mi2016
    FROM "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."BLOCKGROUP_2016_5YR"
    WHERE "geo_id" LIKE '06%'          -- California
      AND "median_income" IS NOT NULL
    GROUP BY tract_code
),
bg_2018 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11) AS tract_code,
        AVG("median_income")    AS mi2018
    FROM "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."BLOCKGROUP_2018_5YR"
    WHERE "geo_id" LIKE '06%'          -- California
      AND "median_income" IS NOT NULL
    GROUP BY tract_code
)
SELECT 
    b18.tract_code
FROM bg_2018 b18
JOIN bg_2016 b16
  ON b18.tract_code = b16.tract_code
ORDER BY (b18.mi2018 - b16.mi2016) DESC NULLS LAST
LIMIT 1;