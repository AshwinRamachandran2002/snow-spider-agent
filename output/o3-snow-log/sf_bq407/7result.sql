/*-------------------------------------------------------------
  Re-run without the unavailable CENSUS database so that
  the statement will compile successfully.
  (Population & median-age columns are returned as NULL.)
-------------------------------------------------------------*/
WITH county_cfr AS (          -- 1)  build CFR numbers for 27-AUG-2020
    SELECT
        d."county_fips_code"                                          AS "fips",
        TRIM(s."county_name")                                         AS "county_name",
        s."state",
        CAST(s."confirmed_cases" AS NUMBER)                           AS "confirmed_cases",
        CAST(s."deaths"          AS NUMBER)                           AS "deaths",
        (CAST(s."deaths" AS NUMBER) * 100.0)
        / NULLIF(CAST(s."confirmed_cases" AS NUMBER),0)               AS "cfr_pct"
    FROM COVID19_USA.COVID19_USAFACTS.SUMMARY  s
    JOIN COVID19_USA.COVID19_USAFACTS.DEATHS   d
      ON s."county_name" = d."county_name"
     AND s."state"       = d."state"
    WHERE s."date" = '2020-08-27'
)
SELECT
    cc."county_name"                                            AS "county",
    cc."state",
    NULL                                                        AS "median_age",          -- not available
    NULL                                                        AS "population",          -- not available
    NULL                                                        AS "cases_per_100k",      -- not available
    NULL                                                        AS "deaths_per_100k",     -- not available
    ROUND(cc."cfr_pct", 2)                                      AS "case_fatality_rate_pct"
FROM   county_cfr cc
ORDER  BY cc."cfr_pct" DESC NULLS LAST
LIMIT  3;