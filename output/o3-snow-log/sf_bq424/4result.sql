WITH long_term_debt AS (
    SELECT
        id."country_code",
        MAX(id."country_name")                     AS "country_name",
        SUM(id."value")                            AS "total_long_term_debt"
    FROM WORLD_BANK.WORLD_BANK_INTL_DEBT.INTERNATIONAL_DEBT id
    WHERE id."indicator_name" ILIKE '%external debt%'
      AND id."indicator_name" ILIKE '%long-term%'
      AND id."value" IS NOT NULL
    GROUP BY id."country_code"
),
valid_countries AS (
    SELECT
        cs."country_code"
    FROM WORLD_BANK.WORLD_BANK_INTL_DEBT.COUNTRY_SUMMARY cs
    WHERE cs."region" IS NOT NULL
)
SELECT
    ltd."country_name",
    ltd."total_long_term_debt"
FROM long_term_debt ltd
JOIN valid_countries vc
  ON ltd."country_code" = vc."country_code"
ORDER BY
    ltd."total_long_term_debt" DESC NULLS LAST
LIMIT 10;