WITH unique_transactions AS (
    SELECT DISTINCT
        "hits_transaction_transactionId" AS "transactionId",
        "channelGrouping",
        "geoNetwork_country" AS "country"
    FROM "ECOMMERCE"."ECOMMERCE"."REV_TRANSACTIONS"
    WHERE "hits_transaction_transactionId" IS NOT NULL
      AND "geoNetwork_country" IS NOT NULL
      AND "geoNetwork_country" != '(not set)'
),
countries_per_channel AS (
    SELECT
        "channelGrouping",
        COUNT(DISTINCT "country") AS "country_count"
    FROM unique_transactions
    GROUP BY "channelGrouping"
),
channels_with_multiple_countries AS (
    SELECT "channelGrouping"
    FROM countries_per_channel
    WHERE "country_count" > 1
),
transactions_per_channel_country AS (
    SELECT
        "channelGrouping",
        "country",
        COUNT(*) AS "total_transactions"
    FROM unique_transactions
    WHERE "channelGrouping" IN (SELECT "channelGrouping" FROM channels_with_multiple_countries)
    GROUP BY "channelGrouping", "country"
),
ranked_transactions AS (
    SELECT
        "channelGrouping",
        "country",
        "total_transactions",
        ROW_NUMBER() OVER (
            PARTITION BY "channelGrouping"
            ORDER BY "total_transactions" DESC NULLS LAST, "country" ASC
        ) AS rn
    FROM transactions_per_channel_country
)
SELECT
    "channelGrouping",
    "country",
    "total_transactions"
FROM ranked_transactions
WHERE rn = 1
ORDER BY "channelGrouping" ASC NULLS LAST;