WITH pop AS (  /* 2017 & 2018 total–population values per country */
    SELECT
        "country_code"  AS COUNTRY_CODE,
        "year_2017"     AS POP_2017,
        "year_2018"     AS POP_2018
    FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY
    WHERE "year_2017" IS NOT NULL
      AND "year_2018" IS NOT NULL
),
pop_growth AS ( /* countries with >1 % population growth */
    SELECT
        COUNTRY_CODE
    FROM pop
    WHERE POP_2017 <> 0
      AND (POP_2018 - POP_2017) / POP_2017 > 0.01
),

/* ----------------------------------------------- */
/*  Per-capita current health-expenditure, PPP      */
hce_ppp_codes AS (
    SELECT DISTINCT "series_code"
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.SERIES_SUMMARY
    WHERE LOWER("indicator_name") LIKE '%current health expenditure per capita%'
      AND LOWER("indicator_name") LIKE '%ppp%'
),

hce AS (  /* 2017 & 2018 PPP per-capita health-expenditure values */
    SELECT
        h."country_code" AS COUNTRY_CODE,
        MAX(CASE WHEN h."year" = 2017 THEN h."value" END) AS HCE_2017,
        MAX(CASE WHEN h."year" = 2018 THEN h."value" END) AS HCE_2018
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION h
    WHERE h."indicator_code" IN (SELECT "series_code" FROM hce_ppp_codes)
      AND h."year" IN (2017, 2018)
    GROUP BY h."country_code"
    HAVING HCE_2017 IS NOT NULL
       AND HCE_2018 IS NOT NULL
),

hce_growth AS ( /* countries with >1 % expenditure growth */
    SELECT
        COUNTRY_CODE
    FROM hce
    WHERE HCE_2017 <> 0
      AND (HCE_2018 - HCE_2017) / HCE_2017 > 0.01
)

/* ----------------------------------------------- */
SELECT COUNT(*) AS COUNTRIES_COUNT
FROM (
    SELECT COUNTRY_CODE FROM pop_growth
    INTERSECT
    SELECT COUNTRY_CODE FROM hce_growth
);