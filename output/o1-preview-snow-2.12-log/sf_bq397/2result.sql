WITH unique_transactions AS (
    SELECT DISTINCT *
    FROM ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
),
multi_country_channels AS (
    SELECT "channelGrouping"
    FROM unique_transactions
    GROUP BY "channelGrouping"
    HAVING COUNT(DISTINCT "geoNetwork_country") > 1
),
country_transactions AS (
    SELECT
        ut."channelGrouping",
        ut."geoNetwork_country",
        SUM(ut."totals_transactions") AS total_transactions
    FROM unique_transactions ut
    WHERE ut."channelGrouping" IN (SELECT "channelGrouping" FROM multi_country_channels)
    GROUP BY ut."channelGrouping", ut."geoNetwork_country"
),
ranked_countries AS (
    SELECT
        ct."channelGrouping",
        ct."geoNetwork_country" AS country,
        ct.total_transactions,
        ROW_NUMBER() OVER (
            PARTITION BY ct."channelGrouping"
            ORDER BY ct.total_transactions DESC NULLS LAST
        ) AS rank
    FROM country_transactions ct
)
SELECT
    "channelGrouping",
    country,
    total_transactions
FROM ranked_countries
WHERE rank = 1;