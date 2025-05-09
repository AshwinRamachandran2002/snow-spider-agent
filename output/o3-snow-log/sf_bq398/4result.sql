WITH indicator_max AS (
    SELECT
        "indicator_name",
        "indicator_code",
        MAX("value") AS "max_value"
    FROM WORLD_BANK.WORLD_BANK_INTL_DEBT."INTERNATIONAL_DEBT"
    WHERE "country_code" = 'RUS'
    GROUP BY
        "indicator_name",
        "indicator_code"
)
SELECT
    "indicator_name",
    "indicator_code",
    "max_value"
FROM indicator_max
ORDER BY
    "max_value" DESC NULLS LAST
LIMIT 3;