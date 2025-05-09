WITH inc_2015 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11)                AS tract_code,
        AVG("median_income")                   AS med_inc_2015
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2016_5YR
    WHERE SUBSTR("geo_id", 1, 2) = '06'                -- California
      AND "median_income" IS NOT NULL
    GROUP BY tract_code
), 
inc_2018 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11)                AS tract_code,
        AVG("median_income")                   AS med_inc_2018
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE SUBSTR("geo_id", 1, 2) = '06'                -- California
      AND "median_income" IS NOT NULL
    GROUP BY tract_code
),
diffs AS (
    SELECT 
        p.tract_code,
        i.med_inc_2018 - p.med_inc_2015        AS income_increase
    FROM inc_2015 p
    JOIN inc_2018 i
      ON p.tract_code = i.tract_code
)
SELECT tract_code
FROM diffs
ORDER BY income_increase DESC NULLS LAST
LIMIT 1;