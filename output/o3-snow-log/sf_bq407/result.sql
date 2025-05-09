/*  -----------------------------------------------------------------------
    Top-3 U.S. counties by COVID-19 case-fatality rate on 27-Aug-2020
    (using only the available COVID-19 county-level tables)
    – Population / median-age data unavailable in current workspace
------------------------------------------------------------------------ */
WITH covid AS (
    SELECT
        c."county_fips_code",
        TRIM(c."county_name")                  AS "county_name",
        c."state",
        c."_2020_08_27"::NUMBER               AS "confirmed_cases",
        d."_2020_08_27"::NUMBER               AS "deaths"
    FROM  COVID19_USA.COVID19_USAFACTS.CONFIRMED_CASES  c
    JOIN  COVID19_USA.COVID19_USAFACTS.DEATHS           d
          ON c."county_fips_code" = d."county_fips_code"
    WHERE c."county_fips_code" <> '00000'               -- exclude unallocated rows
          AND c."_2020_08_27" > 0                       -- avoid div-by-zero
)
/* ----------------------------------------------------------------------
   Result set (population / median-age fields returned as NULL placeholders
   because the ACS 2020 5-year county table is not accessible)
------------------------------------------------------------------------ */
SELECT
    "county_name",
    "state",
    NULL::NUMBER          AS "median_age",
    NULL::NUMBER          AS "total_population",
    NULL::NUMBER          AS "cases_per_100k",
    NULL::NUMBER          AS "deaths_per_100k",
    ROUND( ("deaths" / NULLIF("confirmed_cases",0)) * 100, 4 ) AS "case_fatality_rate_pct"
FROM covid
ORDER BY "case_fatality_rate_pct" DESC NULLS LAST
LIMIT 3;