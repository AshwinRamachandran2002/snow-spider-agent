WITH t2016 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11) AS "tract_code",
        AVG("median_income")     AS "median_2016"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2016_5YR
    WHERE "geo_id" LIKE '06%'                    -- California (state FIPS = 06)
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id", 1, 11)
),
t2018 AS (
    SELECT 
        SUBSTR("geo_id", 1, 11) AS "tract_code",
        AVG("median_income")     AS "median_2018"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '06%'
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id", 1, 11)
),
diffs AS (
    SELECT
        t18."tract_code",
        t16."median_2016",
        t18."median_2018",
        t18."median_2018" - t16."median_2016" AS "income_increase"
    FROM t2018 t18
    JOIN t2016 t16
      ON t18."tract_code" = t16."tract_code"
)
SELECT "tract_code"
FROM diffs
ORDER BY "income_increase" DESC NULLS LAST
LIMIT 1;