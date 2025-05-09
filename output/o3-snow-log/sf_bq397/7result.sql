/* 1. Remove exact–duplicate rows from REV_TRANSACTIONS
   2. Aggregate transactions per (channelGrouping , country)
   3. Keep only channelGroupings that appear in more than one country
   4. Within each of those channelGroupings pick the country with the
      largest total number of transactions                                            */

WITH dedup AS (      -- step-1 : de-duplicate
    SELECT DISTINCT
           "channelGrouping",
           "geoNetwork_country"      AS "country",
           "totals_transactions"
    FROM   ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
    WHERE  "geoNetwork_country" IS NOT NULL
),

agg AS (              -- step-2 : total transactions by country
    SELECT
           "channelGrouping",
           "country",
           SUM(COALESCE("totals_transactions",0)) AS "total_transactions"
    FROM   dedup
    GROUP  BY "channelGrouping","country"
),

ranked AS (           -- step-3/4 : rank countries inside each channel grouping
    SELECT
           "channelGrouping",
           "country",
           "total_transactions",
           ROW_NUMBER() OVER (PARTITION BY "channelGrouping"
                              ORDER BY "total_transactions" DESC, "country") AS rn,
           COUNT(DISTINCT "country") OVER (PARTITION BY "channelGrouping")     AS country_cnt
    FROM   agg
)

SELECT
       "channelGrouping",
       "country",
       "total_transactions"
FROM   ranked
WHERE  rn = 1                 -- top country per channelGrouping
  AND  country_cnt > 1        -- only channelGroupings with >1 country
ORDER BY "channelGrouping";