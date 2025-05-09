WITH income_2016 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11)        AS "tract_code",
        AVG("median_income")           AS "median_income_2016"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2016_5YR
    WHERE SUBSTR("geo_id", 1, 2) = '06'            -- California
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id", 1, 11)
),
income_2018 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11)        AS "tract_code",
        AVG("median_income")           AS "median_income_2018"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE SUBSTR("geo_id", 1, 2) = '06'            -- California
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id", 1, 11)
)
SELECT 
    i18."tract_code"
FROM income_2016 i16
JOIN income_2018 i18
      ON i16."tract_code" = i18."tract_code"
ORDER BY (i18."median_income_2018" - i16."median_income_2016") DESC NULLS LAST
LIMIT 1;