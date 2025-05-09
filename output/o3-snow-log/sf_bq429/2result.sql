WITH inc_2015 AS (
    SELECT
        s."state",
        AVG(z15."median_income") AS "avg_inc_2015"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z15
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"                s
      ON TO_NUMBER(SUBSTRING(z15."geo_id",1,2)) = s."fips"
    WHERE z15."median_income" IS NOT NULL
    GROUP BY s."state"
),
inc_2018 AS (
    SELECT
        s."state",
        AVG(z18."median_income") AS "avg_inc_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z18
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"                s
      ON TO_NUMBER(SUBSTRING(z18."geo_id",1,2)) = s."fips"
    WHERE z18."median_income" IS NOT NULL
    GROUP BY s."state"
),
inc_diff AS (
    SELECT
        i18."state",
        i18."avg_inc_2018" - i15."avg_inc_2015" AS "avg_income_diff"
    FROM inc_2018 i18
    JOIN inc_2015 i15
      ON i18."state" = i15."state"
),
vuln_2017 AS (
    SELECT
        s."state",
        AVG(
              COALESCE(z17."employed_wholesale_trade",0)                                           * 0.38423645320197042
            + COALESCE(z17."employed_construction",0)                                              * 0.48071410777129553   -- natural resources & construction
            + COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0)          * 0.89455676291236841
            + COALESCE(z17."employed_information",0)                                               * 0.31315240083507306
            + COALESCE(z17."employed_retail_trade",0)                                              * 0.51
        ) AS "avg_vulnerable_emp_2017"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR" z17
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"                    s
      ON TO_NUMBER(SUBSTRING(z17."geo_id",1,2)) = s."fips"
    GROUP BY s."state"
)
SELECT
    d."state",
    ROUND(d."avg_income_diff", 4)          AS "avg_income_diff",
    ROUND(v."avg_vulnerable_emp_2017", 4)  AS "avg_vulnerable_emp_2017"
FROM inc_diff d
JOIN vuln_2017 v
  ON d."state" = v."state"
ORDER BY d."avg_income_diff" DESC NULLS LAST
LIMIT 5;