WITH latest_long_term_debt AS (      -- latest non-null value of long-term external debt for each country
    SELECT
        d."country_code",
        d."country_name",
        d."value"                       AS "long_term_debt_usd",
        ROW_NUMBER() OVER (
            PARTITION BY d."country_code"
            ORDER BY d."year" DESC
        )                               AS rn
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA d
    WHERE d."indicator_code" = 'DT.DOD.DLXF.CD'     -- long-term external debt (current US$)
      AND d."value" IS NOT NULL
),
countries_with_region AS (            -- keep only countries that have a region specified
    SELECT
        c."country_code",
        c."region"
    FROM WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY c
    WHERE c."region" IS NOT NULL
      AND TRIM(c."region") <> ''
)
SELECT
    l."country_name",
    l."long_term_debt_usd"
FROM latest_long_term_debt l
JOIN countries_with_region r
  ON l."country_code" = r."country_code"
WHERE l.rn = 1                         -- latest year only
ORDER BY l."long_term_debt_usd" DESC NULLS LAST
LIMIT 10;