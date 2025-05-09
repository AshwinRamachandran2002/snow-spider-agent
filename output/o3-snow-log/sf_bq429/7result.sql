/* Top 5 states by average change in median household income (2018–2015)
   together with the average number of vulnerable employees (2017)
   at the ZIP-code level                                           */

WITH income_diff AS (        -- 2018 vs 2015 income change per ZIP
    SELECT  z18."geo_id",
            (z18."median_income" - z15."median_income") AS "income_diff_18_15"
    FROM    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR"  z18
    JOIN    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR"  z15
           ON z18."geo_id" = z15."geo_id"
),
vuln AS (                    -- 2017 weighted vulnerable-employee count per ZIP
    SELECT  z17."geo_id",
            ( COALESCE(z17."employed_wholesale_trade",0)                              * 0.38423645320197042
            + COALESCE(z17."employed_construction",0)                                 * 0.48071410777129553   -- natural resources & construction
            + COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0) * 0.89455676291236841
            + COALESCE(z17."employed_information",0)                                  * 0.31315240083507306
            + COALESCE(z17."employed_retail_trade",0)                                 * 0.51
            ) AS "weighted_vulnerable_employees_2017"
    FROM    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR"  z17
),
combined AS (                -- merge income change and vulnerability, attach state FIPS
    SELECT  i."geo_id",
            i."income_diff_18_15",
            v."weighted_vulnerable_employees_2017",
            TO_NUMBER(SUBSTR(i."geo_id",1,2))        AS "state_fips"
    FROM    income_diff i
    JOIN    vuln        v  ON i."geo_id" = v."geo_id"
)
SELECT  s."state"        AS "state_name",
        s."postal_code"  AS "state_abbr",
        AVG(c."income_diff_18_15")              AS "avg_income_diff_2018_vs_2015",
        AVG(c."weighted_vulnerable_employees_2017") AS "avg_weighted_vulnerable_employees_2017"
FROM    combined c
JOIN    "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" s
       ON c."state_fips" = s."fips"
GROUP BY s."state", s."postal_code"
ORDER BY "avg_income_diff_2018_vs_2015" DESC NULLS LAST
LIMIT 5;