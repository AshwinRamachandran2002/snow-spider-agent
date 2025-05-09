-- For every channelGrouping that records transactions in more than one country,
-- return the country with the highest total number of transactions
-- (after removing duplicate rows).

WITH dedup AS (        -- 1. De-duplicate the source table
  SELECT DISTINCT
         `channelGrouping`,
         `geoNetwork_country`            AS country,
         `totals_transactions`           AS transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
),

agg AS (               -- 2. Sum transactions per (channel, country)
  SELECT
         channelGrouping,
         country,
         SUM(IFNULL(transactions,0))     AS total_transactions
  FROM dedup
  GROUP BY channelGrouping, country
),

ranked AS (            -- 3. Keep only channel groupings spanning >1 country,
                       --    and rank countries by their transaction totals
  SELECT
         channelGrouping,
         country,
         total_transactions,
         ROW_NUMBER() OVER (PARTITION BY channelGrouping
                            ORDER BY total_transactions DESC)        AS rn,
         COUNT(DISTINCT country) OVER (PARTITION BY channelGrouping) AS countries_cnt
  FROM agg
)

SELECT
       channelGrouping,
       country  AS top_country,
       total_transactions
FROM ranked
WHERE rn = 1               -- top country per channelGrouping
  AND countries_cnt > 1    -- only channels with >1 country
ORDER BY channelGrouping;