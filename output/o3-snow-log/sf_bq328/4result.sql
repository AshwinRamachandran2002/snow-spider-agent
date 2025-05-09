WITH latest_gdp_per_country AS (
    /* get the most recent non-null GDP (constant 2015 US$) for every country */
    SELECT
        id."country_code",
        id."value",
        ROW_NUMBER() OVER (PARTITION BY id."country_code"
                           ORDER BY id."year" DESC NULLS LAST) AS rn
    FROM WORLD_BANK.WORLD_BANK_WDI."INDICATORS_DATA" AS id
    WHERE id."indicator_code" = 'NY.GDP.MKTP.KD'           -- GDP (constant 2015 US$)
      AND id."value" IS NOT NULL
),
country_gdp AS (
    /* keep only that latest record per country */
    SELECT "country_code", "value"
    FROM latest_gdp_per_country
    WHERE rn = 1
),
gdp_with_region AS (
    /* attach each country’s World Bank region (exclude aggregate rows that lack a region) */
    SELECT
        cs."region",
        cg."value"
    FROM country_gdp          AS cg
    JOIN WORLD_BANK.WORLD_BANK_WDI."COUNTRY_SUMMARY" AS cs
          ON cg."country_code" = cs."country_code"
    WHERE cs."region" IS NOT NULL                       -- filters out regional aggregate codes
)
SELECT
    "region",
    MEDIAN("value") AS median_gdp_constant_2015_usd
FROM gdp_with_region
GROUP BY "region"
ORDER BY median_gdp_constant_2015_usd DESC NULLS LAST
LIMIT 1;