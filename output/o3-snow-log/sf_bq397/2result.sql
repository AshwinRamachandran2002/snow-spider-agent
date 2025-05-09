/* 1. Deduplicate REV_TRANSACTIONS
   2. Aggregate transactions by Channel + Country
   3. Keep only channel groupings that appear in more than one country
   4. For each such channel, pick the country with the largest
      summed-transactions (ties resolved alphabetically)          */

WITH dedup AS (        -- remove duplicate rows first
    SELECT DISTINCT
           "channelGrouping",
           "geoNetwork_country"            AS "country",
           COALESCE("totals_transactions",0) AS "transactions"
    FROM   ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
    WHERE  "totals_transactions" IS NOT NULL
      AND  "geoNetwork_country"  IS NOT NULL
),

agg AS (               -- total transactions per Channel + Country
    SELECT
        "channelGrouping",
        "country",
        SUM("transactions")              AS "total_transactions"
    FROM dedup
    GROUP BY
        "channelGrouping",
        "country"
),

eligible_channels AS ( -- channels present in >1 country
    SELECT
        "channelGrouping"
    FROM agg
    GROUP BY "channelGrouping"
    HAVING COUNT(DISTINCT "country") > 1
),

ranked AS (            -- rank countries inside each channel by volume
    SELECT
        a."channelGrouping",
        a."country",
        a."total_transactions",
        ROW_NUMBER() OVER (PARTITION BY a."channelGrouping"
                           ORDER BY a."total_transactions" DESC,
                                    a."country"              ASC) AS rn
    FROM agg a
    JOIN eligible_channels e
      ON a."channelGrouping" = e."channelGrouping"
)

SELECT
    "channelGrouping",
    "country",
    "total_transactions"
FROM   ranked
WHERE  rn = 1                 -- top country per eligible channel
ORDER  BY "channelGrouping";