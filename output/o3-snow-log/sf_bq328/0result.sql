WITH latest_country_gdp AS (           -- latest non-null GDP (constant 2015 US$) per country
    SELECT
        d."country_code",
        d."value"  AS "gdp_const_2015"
    FROM (
        SELECT
            "country_code",
            "value",
            ROW_NUMBER() OVER (PARTITION BY "country_code"
                               ORDER BY "year" DESC) AS rn
        FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA
        WHERE "indicator_code" = 'NY.GDP.MKTP.KD'    -- GDP, constant 2015 US$
          AND "value" IS NOT NULL
    ) d
    WHERE rn = 1
),
country_region AS (                    -- keep only countries mapped to a WB region
    SELECT
        "country_code",
        "region"
    FROM WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY
    WHERE "region" IS NOT NULL
)

SELECT
    cr."region",
    MEDIAN(l."gdp_const_2015") AS "median_gdp_const_2015_usd"
FROM latest_country_gdp l
JOIN country_region cr
  ON l."country_code" = cr."country_code"
GROUP BY cr."region"
ORDER BY "median_gdp_const_2015_usd" DESC NULLS LAST
LIMIT 1;