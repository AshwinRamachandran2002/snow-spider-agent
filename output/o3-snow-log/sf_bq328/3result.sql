WITH gdp_per_country AS (
    SELECT
        cs."region",
        id."value"
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA AS id
    JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY AS cs
      ON id."country_code" = cs."country_code"
    WHERE id."indicator_code" = 'NY.GDP.MKTP.KD'   -- GDP (constant 2015 US$)
      AND id."value" IS NOT NULL
      AND cs."region" IS NOT NULL
), region_medians AS (
    SELECT
        "region",
        MEDIAN("value") AS "median_gdp_2015_USD"
    FROM gdp_per_country
    GROUP BY "region"
)
SELECT
    "region",
    "median_gdp_2015_USD"
FROM region_medians
ORDER BY "median_gdp_2015_USD" DESC NULLS LAST
LIMIT 1;