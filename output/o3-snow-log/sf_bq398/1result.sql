WITH russian_debt_peaks AS (
    SELECT
        "indicator_code",
        "indicator_name",
        MAX("value") AS "max_value"
    FROM
        WORLD_BANK.WORLD_BANK_INTL_DEBT.INTERNATIONAL_DEBT
    WHERE
        "country_code" = 'RUS'
        AND "indicator_code" ILIKE 'DT.%'     -- consider only debt-related indicators
        AND "value" IS NOT NULL
    GROUP BY
        "indicator_code",
        "indicator_name"
)
SELECT
    "indicator_code",
    "indicator_name",
    "max_value"
FROM
    russian_debt_peaks
ORDER BY
    "max_value" DESC NULLS LAST
LIMIT 3;