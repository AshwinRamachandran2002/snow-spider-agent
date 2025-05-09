WITH latest_debt AS (
    SELECT
        d."country_code",
        d."country_name",
        d."year",
        d."value",
        ROW_NUMBER() OVER (PARTITION BY d."country_code"
                           ORDER BY d."year" DESC) AS rn
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA d
    WHERE d."indicator_code" = 'DT.DOD.DLXF.CD'      -- Long-term external debt stocks, total (current US$)
      AND d."value" IS NOT NULL
)
SELECT
    ld."country_name",
    ld."value"      AS "long_term_external_debt_usd",
    ld."year"       AS "reference_year"
FROM latest_debt ld
JOIN WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY cs
  ON ld."country_code" = cs."country_code"
WHERE ld.rn = 1
  AND cs."region" IS NOT NULL          -- exclude aggregates with no region
ORDER BY ld."value" DESC NULLS LAST
LIMIT 10;