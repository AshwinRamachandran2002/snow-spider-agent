/*  Top-5 states (by 2–digit ZIP state-FIPS prefix) with the largest
    2018-vs-2015 median-income jump and their corresponding 2017 average
    “vulnerable-employees” counts.                                            */

WITH income_2015 AS (
    SELECT
        SUBSTR("geo_id",1,2)                         AS "state_fips_prefix",
        AVG("median_income")                         AS "avg_median_income_2015"
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"
    WHERE  "median_income" IS NOT NULL
    GROUP  BY 1
), income_2018 AS (
    SELECT
        SUBSTR("geo_id",1,2)                         AS "state_fips_prefix",
        AVG("median_income")                         AS "avg_median_income_2018"
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
    WHERE  "median_income" IS NOT NULL
    GROUP  BY 1
), income_diff AS (
    SELECT
        i18."state_fips_prefix",
        i18."avg_median_income_2018" 
        -  i15."avg_median_income_2015"              AS "income_diff_18_15"
    FROM   income_2018 i18
    JOIN   income_2015 i15
      ON   i18."state_fips_prefix" = i15."state_fips_prefix"
), vulnerable_2017 AS (
    SELECT
        SUBSTR("geo_id",1,2)                         AS "state_fips_prefix",
        AVG(
             COALESCE("employed_wholesale_trade",0)  * 0.38423645320197042 +
             COALESCE("employed_construction",0)     * 0.48071410777129553 +
             COALESCE("employed_arts_entertainment_recreation_accommodation_food",0)
                                                    * 0.89455676291236841 +
             COALESCE("employed_information",0)      * 0.31315240083507306 +
             COALESCE("employed_retail_trade",0)     * 0.51
        )                                            AS "avg_vulnerable_emp_2017"
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
    GROUP  BY 1
)
SELECT
    d."state_fips_prefix",
    d."income_diff_18_15",
    v."avg_vulnerable_emp_2017"
FROM   income_diff      d
JOIN   vulnerable_2017  v
  ON   d."state_fips_prefix" = v."state_fips_prefix"
ORDER  BY d."income_diff_18_15" DESC NULLS LAST
LIMIT 5;