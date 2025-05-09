WITH income_diff AS (   -- 1.  change in median household income from 2015 → 2018 at ZIP level
    SELECT
        z18."geo_id",
        z18."median_income" - z15."median_income" AS "income_change"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" z18
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" z15
          ON z18."geo_id" = z15."geo_id"
), 

vulnerable_emp AS (     -- 2.  2017 vulnerability-weighted employment count for each ZIP
    SELECT
        z17."geo_id",
        /* vulnerability weights supplied in the prompt */
        ( COALESCE(z17."employed_wholesale_trade", 0)  * 0.38423645320197042 +
          COALESCE(z17."employed_construction",     0) * 0.48071410777129553 +   -- natural resources & construction
          COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food", 0) * 0.89455676291236841 +
          COALESCE(z17."employed_information",      0) * 0.31315240083507306 +
          COALESCE(z17."employed_retail_trade",     0) * 0.51000000000000000 )  AS "vulnerable_employees"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR" z17
)

SELECT
    s."state",
    AVG(i."income_change")        AS "avg_income_change_2015_2018",
    AVG(v."vulnerable_employees") AS "avg_vulnerable_employees_2017"
FROM income_diff  i
JOIN vulnerable_emp v   ON i."geo_id" = v."geo_id"                  -- keep ZIPs present in all three years
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"  s
     ON TRY_TO_NUMBER( SUBSTR(i."geo_id", 1, 2) ) = s."fips"        -- map ZIP prefix → state FIPS
GROUP BY s."state"
ORDER BY "avg_income_change_2015_2018" DESC NULLS LAST
LIMIT 5;