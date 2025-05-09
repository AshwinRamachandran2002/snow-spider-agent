WITH dedup AS (   -- remove duplicate rows and keep one record per transaction
    SELECT DISTINCT
           "channelGrouping",
           "geoNetwork_country"                          AS "country",
           "hits_transaction_transactionId"              AS "transaction_id"
    FROM   ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
    WHERE  "hits_transaction_transactionId" IS NOT NULL
      AND  "geoNetwork_country" IS NOT NULL
),

country_totals AS (   -- count unique transactions per country & channel group
    SELECT
           "channelGrouping",
           "country",
           COUNT(DISTINCT "transaction_id") AS txn_cnt
    FROM   dedup
    GROUP  BY "channelGrouping", "country"
),

ranked AS (   -- retain only the top-country per channel group
    SELECT
           ct.*,
           COUNT(DISTINCT "country") OVER (PARTITION BY "channelGrouping") AS countries_in_group,
           ROW_NUMBER() OVER (PARTITION BY "channelGrouping"
                              ORDER BY txn_cnt DESC, "country")           AS rn
    FROM   country_totals ct
)

SELECT
       "channelGrouping",
       "country",
       txn_cnt AS total_transactions
FROM   ranked
WHERE  countries_in_group > 1   -- channel group must have > 1 country
  AND  rn = 1                    -- keep the country with highest transactions
ORDER BY "channelGrouping";