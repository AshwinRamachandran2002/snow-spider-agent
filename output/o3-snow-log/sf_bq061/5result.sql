WITH t2016 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11) AS tract_code,
        AVG("median_income") AS median_income_2016
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2016_5YR
    WHERE "median_income" IS NOT NULL 
      AND SUBSTR("geo_id", 1, 2) = '06'         -- California state FIPS
    GROUP BY SUBSTR("geo_id", 1, 11)
),
t2018 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11) AS tract_code,
        AVG("median_income") AS median_income_2018
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "median_income" IS NOT NULL 
      AND SUBSTR("geo_id", 1, 2) = '06'         -- California state FIPS
    GROUP BY SUBSTR("geo_id", 1, 11)
),
income_change AS (
    SELECT 
        e.tract_code,
        e.median_income_2018 - s.median_income_2016 AS income_increase
    FROM t2018 e
    JOIN t2016 s
      ON e.tract_code = s.tract_code
)
SELECT tract_code
FROM income_change
ORDER BY income_increase DESC NULLS LAST
LIMIT 1;