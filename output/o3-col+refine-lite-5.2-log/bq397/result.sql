-- FINAL ANSWER:  country with the highest summed transactions
--                for every channel grouping that sells in >1 country
WITH dedup AS (
  -- 1. de‑duplicate the source table
  SELECT DISTINCT *
  FROM `data-to-insights.ecommerce.rev_transactions`
),
agg AS (
  -- 2. aggregate transactions per (channelGrouping, country)
  SELECT
    channelGrouping,
    geoNetwork_country            AS country,
    SUM(totals_transactions)      AS total_transactions
  FROM dedup
  GROUP BY channelGrouping, country
),
qualified AS (
  -- 3. keep only channel groupings present in >1 country
  SELECT channelGrouping
  FROM agg
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),
ranked AS (
  -- 4. rank countries within each qualifying channel grouping
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY channelGrouping
                       ORDER BY total_transactions DESC) AS rn
  FROM agg AS a
  JOIN qualified USING (channelGrouping)
)
-- 5. return the top‑ranked country per channel grouping
SELECT
  channelGrouping,
  country,
  total_transactions
FROM ranked
WHERE rn = 1
ORDER BY channelGrouping;