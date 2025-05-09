-- Top three debt indicators for Russia based on their highest recorded debt values
SELECT
    "indicator_name",
    "indicator_code",
    MAX("value") AS "max_value"
FROM WORLD_BANK.WORLD_BANK_INTL_DEBT."INTERNATIONAL_DEBT"
WHERE "country_code" = 'RUS'
  AND "value" IS NOT NULL
GROUP BY
    "indicator_name",
    "indicator_code"
ORDER BY
    "max_value" DESC NULLS LAST
LIMIT 3;