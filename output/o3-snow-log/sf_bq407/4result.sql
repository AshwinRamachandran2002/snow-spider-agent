/* ---------------------------------------------------------------
   Top-3 counties by COVID-19 case-fatality rate on 2020-08-27   
   (using only the available COVID19_USA.COVID19_USAFACTS tables)
   ------------------------------------------------------------- */
WITH county_covid AS (
    SELECT
        c."county_fips_code",
        TRIM(c."county_name")                        AS "county_name",
        c."state",
        c."_2020_08_27"                              AS "confirmed_cases",
        d."_2020_08_27"                              AS "deaths",
        ROUND(d."_2020_08_27" / NULLIF(c."_2020_08_27",0) * 100 , 2) 
                                                    AS "case_fatality_pct"
    FROM COVID19_USA.COVID19_USAFACTS.CONFIRMED_CASES  AS c
    JOIN COVID19_USA.COVID19_USAFACTS.DEATHS           AS d
      ON  c."county_fips_code" = d."county_fips_code"
      AND c."state"            = d."state"
    WHERE c."county_fips_code" <> '00000'           -- exclude statewide unallocated
)
/* Return the 3 counties with the highest CFR  */
SELECT
    "county_name",
    "state",
    CAST(NULL AS NUMBER)  AS "median_age",          -- placeholder (census data unavailable)
    CAST(NULL AS NUMBER)  AS "total_population",    -- placeholder
    CAST(NULL AS NUMBER)  AS "cases_per_100k",      -- placeholder
    CAST(NULL AS NUMBER)  AS "deaths_per_100k",     -- placeholder
    "case_fatality_pct"
FROM county_covid
ORDER BY "case_fatality_pct" DESC NULLS LAST
LIMIT 3;