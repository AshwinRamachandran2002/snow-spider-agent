WITH income_diff AS (
    SELECT
        zgeo."state_code",                       -- two‑letter state code
        z17."geo_id"                      AS "zip",
        z17."employed_wholesale_trade",
        z17."employed_manufacturing"
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  AS z17
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  AS z15
          USING ("geo_id")
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  AS z18
          USING ("geo_id")
    JOIN  CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"           AS zgeo
          ON  zgeo."zip_code" = z17."geo_id"
    WHERE ( z18."median_income" - z15."median_income" ) < 0           -- income declined
)

SELECT
    st."state_name"                                          AS "state",
    SUM( 0.38 * COALESCE(d."employed_wholesale_trade",0) )   AS "vulnerable_wholesale_trade_workers",
    SUM( 0.41 * COALESCE(d."employed_manufacturing",0) )     AS "vulnerable_manufacturing_workers",
    SUM( 0.38 * COALESCE(d."employed_wholesale_trade",0)
        + 0.41 * COALESCE(d."employed_manufacturing",0) )    AS "total_vulnerable_workers"
FROM income_diff AS d
LEFT JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."STATES" AS st
       ON st."state" = d."state_code"
GROUP BY st."state_name"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST;