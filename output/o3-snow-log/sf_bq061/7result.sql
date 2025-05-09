WITH income_2015 AS (   -- use 2016 5-yr ACS as closest proxy for 2015
    SELECT 
        SUBSTR("geo_id",1,11)            AS tract,   -- census-tract code
        AVG("median_income")             AS median2015
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2016_5YR
    WHERE "geo_id" LIKE '06%'            -- California (state FIPS 06)
      AND "median_income" IS NOT NULL
    GROUP BY tract
),
income_2018 AS (
    SELECT 
        SUBSTR("geo_id",1,11)            AS tract,
        AVG("median_income")             AS median2018
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '06%'
      AND "median_income" IS NOT NULL
    GROUP BY tract
),
diff AS (
    SELECT 
        i18.tract,
        i18.median2018 - i15.median2015  AS income_increase
    FROM income_2018 i18
    JOIN income_2015 i15 USING (tract)
)
SELECT tract
FROM diff
ORDER BY income_increase DESC NULLS LAST
LIMIT 1;