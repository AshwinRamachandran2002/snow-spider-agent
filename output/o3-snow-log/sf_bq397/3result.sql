/* 1)  De-duplicate rows from REV_TRANSACTIONS
   2)  Aggregate transactions per (channelGrouping , country)
   3)  Keep only channel groupings present in more than one country
   4)  For each such grouping pick the country with the highest
       total number of transactions                                      */

WITH dedup AS (          -- remove possible duplicate rows
    SELECT DISTINCT
           "channelGrouping",
           "geoNetwork_country",
           "totals_transactions"
    FROM   ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
    WHERE  "geoNetwork_country" IS NOT NULL          -- ignore NULL country rows
),

agg AS (                 -- total transactions per country & channel
    SELECT
        "channelGrouping",
        "geoNetwork_country"               AS country,
        SUM( COALESCE("totals_transactions",0) )  AS total_transactions
    FROM dedup
    GROUP BY
        "channelGrouping",
        "geoNetwork_country"
),

ranked AS (              -- rank countries inside every channel grouping
    SELECT
        a.*,
        COUNT(DISTINCT country) 
              OVER (PARTITION BY "channelGrouping")          AS country_cnt,
        ROW_NUMBER() 
              OVER (PARTITION BY "channelGrouping"
                        ORDER BY total_transactions DESC NULLS LAST,
                                 country                       )  AS rn
    FROM agg a
)

SELECT
    "channelGrouping"                 AS channel_grouping,
    country,
    total_transactions
FROM   ranked
WHERE  country_cnt > 1        -- keep only groupings with >1 countries
  AND  rn = 1                 -- pick top-country per grouping
ORDER BY
    channel_grouping;