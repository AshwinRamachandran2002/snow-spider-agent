WITH debt_rows AS (
    SELECT
        "country_code",
        "country_name",
        "value",
        "year",
        ROW_NUMBER() OVER (
            PARTITION BY "country_code"
            ORDER BY "year" DESC
        ) AS "rn"
    FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA
    WHERE "indicator_code" = 'DT.DOD.DLXF.CD'          -- Long-term external debt stocks (current US$)
      AND "value" IS NOT NULL
),
latest_debt AS (
    SELECT
        "country_code",
        "country_name",
        "value" AS "total_long_term_external_debt"
    FROM debt_rows
    WHERE "rn" = 1
),
countries_with_region AS (
    SELECT
        "country_code"
    FROM WORLD_BANK.WORLD_BANK_WDI.COUNTRY_SUMMARY
    WHERE "region" IS NOT NULL
)
SELECT
    l."country_name"                             AS "country",
    l."total_long_term_external_debt"
FROM latest_debt l
JOIN countries_with_region r
  ON l."country_code" = r."country_code"
ORDER BY
    l."total_long_term_external_debt" DESC NULLS LAST
LIMIT 10;