/* Identify, per multi-country channel grouping, the country that drives the
   highest number of transactions (after perfect-row de-duplication). */
WITH dedup AS (     -- 1. drop perfect duplicates
  SELECT DISTINCT *
  FROM `data-to-insights.ecommerce.rev_transactions`
),
agg AS (            -- 2. aggregate transactions by channel & country
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    SUM(totals_transactions) AS total_txns
  FROM dedup
  GROUP BY channelGrouping, country
),
multi_country AS (  -- 3. keep only channels present in >1 country
  SELECT channelGrouping
  FROM agg
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),
ranked AS (         -- 4. rank countries inside each qualifying channel
  SELECT
    a.*,
    RANK() OVER (PARTITION BY channelGrouping ORDER BY total_txns DESC) AS rnk
  FROM agg a
  WHERE a.channelGrouping IN (SELECT channelGrouping FROM multi_country)
)
-- 5. return the top-country per channel
SELECT
  channelGrouping,
  country,
  total_txns
FROM ranked
WHERE rnk = 1
ORDER BY channelGrouping;