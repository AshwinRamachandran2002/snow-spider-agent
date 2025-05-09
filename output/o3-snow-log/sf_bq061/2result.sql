WITH income_2015 AS (
    SELECT
        SUBSTR("geo_id", 1, 11) AS tract_code,
        AVG("median_income")  AS med_2015
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2016_5YR
    WHERE "geo_id" LIKE '06%'          -- California (state FIPS = 06)
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id", 1, 11)
),
income_2018 AS (
    SELECT
        SUBSTR("geo_id", 1, 11) AS tract_code,
        AVG("median_income") AS med_2018
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE "geo_id" LIKE '06%'          -- California
      AND "median_income" IS NOT NULL
    GROUP BY SUBSTR("geo_id", 1, 11)
),
income_change AS (
    SELECT
        i18.tract_code,
        i15.med_2015,
        i18.med_2018,
        i18.med_2018 - i15.med_2015 AS diff_income
    FROM income_2015 i15
    JOIN income_2018 i18
      ON i15.tract_code = i18.tract_code
)
SELECT tract_code
FROM income_change
ORDER BY diff_income DESC NULLS LAST
LIMIT 1;