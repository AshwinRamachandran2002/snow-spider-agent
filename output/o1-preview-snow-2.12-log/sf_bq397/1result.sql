WITH unique_transactions AS (
    SELECT DISTINCT "hits_transaction_transactionId", "channelGrouping", "geoNetwork_country"
    FROM "ECOMMERCE"."ECOMMERCE"."REV_TRANSACTIONS"
    WHERE "hits_transaction_transactionId" IS NOT NULL
),
channels_with_multiple_countries AS (
    SELECT "channelGrouping"
    FROM unique_transactions
    GROUP BY "channelGrouping"
    HAVING COUNT(DISTINCT "geoNetwork_country") > 1
),
transactions_per_country AS (
    SELECT 
        ut."channelGrouping", 
        ut."geoNetwork_country" AS country, 
        COUNT(DISTINCT ut."hits_transaction_transactionId") AS total_transactions
    FROM unique_transactions ut
    WHERE ut."channelGrouping" IN (SELECT "channelGrouping" FROM channels_with_multiple_countries)
    GROUP BY ut."channelGrouping", ut."geoNetwork_country"
),
max_transactions_per_channel AS (
    SELECT 
        tpc."channelGrouping", 
        tpc.country, 
        tpc.total_transactions,
        ROW_NUMBER() OVER (
            PARTITION BY tpc."channelGrouping" 
            ORDER BY tpc.total_transactions DESC NULLS LAST
        ) AS rn
    FROM transactions_per_country tpc
)
SELECT "channelGrouping", country, total_transactions
FROM max_transactions_per_channel
WHERE rn = 1
ORDER BY "channelGrouping";