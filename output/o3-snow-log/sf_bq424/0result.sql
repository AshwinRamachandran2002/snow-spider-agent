/* Top 10 countries by the latest reported value of long-term external debt
   (current US$), excluding countries that have no region assigned        */

WITH long_term_debt AS (          -- all observations of the indicator
    SELECT
        "country_code",
        "country_name",
        "year",
        "value"
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA
    WHERE "indicator_code" = 'DT.DOD.DLXF.CD'      -- long-term external debt stocks (current US$)
      AND "value" IS NOT NULL
),
latest_year AS (                  -- most recent year per country
    SELECT
        "country_code",
        MAX("year") AS "latest_year"
    FROM long_term_debt
    GROUP BY "country_code"
),
latest_debt AS (                  -- debt amount for that latest year
    SELECT
        d."country_code",
        d."country_name",
        d."value" AS "latest_debt_value"
    FROM long_term_debt d
    JOIN latest_year y
      ON d."country_code" = y."country_code"
     AND d."year"         = y."latest_year"
),
with_region AS (                  -- keep only countries that have a region
    SELECT
        ld."country_name",
        ld."latest_debt_value"
    FROM latest_debt ld
    JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY cs
      ON ld."country_code" = cs."country_code"
    WHERE cs."region" IS NOT NULL
)

SELECT
    "country_name",
    "latest_debt_value" AS "long_term_external_debt_current_usd"
FROM with_region
ORDER BY "long_term_external_debt_current_usd" DESC NULLS LAST
LIMIT 10;