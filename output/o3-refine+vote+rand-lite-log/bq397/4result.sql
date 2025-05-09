/* Top‑performing country (by transactions) for each channelGrouping
   that records transactions coming from more than one country          */

WITH dedup AS (
  -- 1.  De‑duplicate the transaction‑level rows
  SELECT DISTINCT
         fullVisitorId,
         visitId,
         channelGrouping,
         geoNetwork_country  AS country,
         COALESCE(totals_transactions,0) AS transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
), 

country_totals AS (
  -- 2.  Aggregate transactions by channel + country
  SELECT
         channelGrouping,
         country,
         SUM(transactions) AS total_transactions
  FROM dedup
  GROUP BY channelGrouping, country
  HAVING total_transactions > 0                 -- keep only rows that contain transactions
), 

multi_country AS (
  -- 3.  Keep only channelGroupings active in >1 country
  SELECT channelGrouping
  FROM   country_totals
  GROUP  BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),

ranked AS (
  -- 4.  Rank countries within each eligible channelGrouping
  SELECT
         ct.channelGrouping,
         ct.country,
         ct.total_transactions,
         ROW_NUMBER() OVER (PARTITION BY ct.channelGrouping
                            ORDER BY ct.total_transactions DESC, ct.country) AS rn
  FROM   country_totals ct
  JOIN   multi_country  mc
  ON     ct.channelGrouping = mc.channelGrouping
)

-- 5.  Return the top‑transaction country per channelGrouping
SELECT
       channelGrouping,
       country      AS top_country,
       total_transactions
FROM   ranked
WHERE  rn = 1
ORDER BY channelGrouping;