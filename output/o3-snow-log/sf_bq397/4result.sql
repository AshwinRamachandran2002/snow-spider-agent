/*  1. Remove exact-duplicate rows first (SELECT DISTINCT).
    2. Count distinct transactions per Country & Channel.
    3. Keep only those Channel Groupings that have transactions coming
       from more than one Country.
    4. For each such Channel, pick the Country with the highest
       transaction count (ties resolved alphabetically).               */

WITH dedup AS (   -- step-1 : de-duplicate the raw table
    SELECT DISTINCT
           "channelGrouping",
           "geoNetwork_country"      AS country,
           "hits_transaction_transactionId" AS transaction_id
    FROM   ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
    WHERE  "hits_transaction_transactionId" IS NOT NULL
),

tx_per_country AS (   -- step-2 : transactions per (channel , country)
    SELECT
        "channelGrouping",
        country,
        COUNT(DISTINCT transaction_id) AS total_transactions
    FROM dedup
    GROUP BY
        "channelGrouping",
        country
),

eligible_channels AS (   -- step-3 : channels with > 1 countries
    SELECT "channelGrouping"
    FROM   tx_per_country
    GROUP BY "channelGrouping"
    HAVING COUNT(DISTINCT country) > 1
),

ranked AS (   -- step-4 : rank countries inside each eligible channel
    SELECT
        t."channelGrouping",
        t.country,
        t.total_transactions,
        ROW_NUMBER() OVER (
            PARTITION BY t."channelGrouping"
            ORDER BY t.total_transactions DESC, t.country
        ) AS rn
    FROM tx_per_country t
    JOIN eligible_channels e
      ON t."channelGrouping" = e."channelGrouping"
)

SELECT
    "channelGrouping",
    country,
    total_transactions
FROM ranked
WHERE rn = 1
ORDER BY "channelGrouping";