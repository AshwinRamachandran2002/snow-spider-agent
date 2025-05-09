-- 1. De‑duplicate the rev_transactions table at visit level
-- 2. Keep only rows that actually have a transaction recorded
-- 3. Aggregate transactions per channel & country
-- 4. Keep only channel groupings active in >1 country
-- 5. For every such channel grouping pick the country with the highest summed transactions
WITH dedup AS (
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    totals_transactions     AS txns
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY visitId) AS rn          -- one row per visit
    FROM `data-to-insights.ecommerce.rev_transactions`
  )
  WHERE rn = 1
    AND totals_transactions IS NOT NULL                       -- retain visits that include a transaction
), 
agg AS (
  SELECT
    channelGrouping,
    country,
    SUM(txns) AS total_txns
  FROM dedup
  GROUP BY channelGrouping, country
), 
multi_country AS (
  SELECT channelGrouping
  FROM agg
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1                          -- channel active in >1 country
), 
ranked AS (
  SELECT
    a.channelGrouping,
    a.country,
    a.total_txns,
    ROW_NUMBER() OVER (PARTITION BY a.channelGrouping
                       ORDER BY a.total_txns DESC, a.country) AS rn
  FROM agg a
  JOIN multi_country m
    ON a.channelGrouping = m.channelGrouping
)
SELECT
  channelGrouping,
  country                       AS top_country_by_transactions,
  total_txns                    AS sum_transactions
FROM ranked
WHERE rn = 1
ORDER BY channelGrouping;