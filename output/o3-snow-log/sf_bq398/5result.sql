-- Top three debt-related indicators for Russia ranked by their single highest recorded value
SELECT
    "indicator_code",
    "indicator_name",
    MAX("value") AS "peak_value_usd"
FROM WORLD_BANK.WORLD_BANK_INTL_DEBT."INTERNATIONAL_DEBT"
WHERE "country_code" = 'RUS'
  AND "value" IS NOT NULL
GROUP BY "indicator_code", "indicator_name"
ORDER BY "peak_value_usd" DESC NULLS LAST
LIMIT 3;