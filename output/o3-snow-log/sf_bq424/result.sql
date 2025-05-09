WITH "latest_debt" AS (
    SELECT
        id."country_code",
        id."country_name",
        id."value" AS "long_term_external_debt_usd",
        id."year",
        ROW_NUMBER() OVER (
            PARTITION BY id."country_code"
            ORDER BY id."year" DESC
        ) AS "rn"
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA id
    WHERE id."indicator_code" = 'DT.DOD.DLXF.CD'      -- External debt stocks, long-term (current US$)
      AND id."value" IS NOT NULL
)

SELECT
    ld."country_name",
    ld."long_term_external_debt_usd"
FROM "latest_debt" ld
JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY cs
      ON ld."country_code" = cs."country_code"
WHERE ld."rn" = 1                   -- keep latest year per country
  AND cs."region" IS NOT NULL       -- exclude entries without a specified region
ORDER BY ld."long_term_external_debt_usd" DESC NULLS LAST
LIMIT 10;