-- 1.  De‑duplicate the rev_transactions table at the visit level  
-- 2.  Keep only those Channel Groupings that appear in more than one country  
-- 3.  For every such Channel Grouping return the country with the
--     highest total number of transactions and the corresponding sum
WITH dedup_visit AS (   -- step 1: remove duplicate rows that belong to the same visit
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    visitId,
    MAX(COALESCE(totals_transactions,0)) AS transactions         -- 1/0 for that visit
  FROM `data-to-insights.ecommerce.rev_transactions`
  GROUP BY channelGrouping, country, visitId
),
transactions_by_country AS (   -- total transactions per channel+country
  SELECT
    channelGrouping,
    country,
    SUM(transactions) AS total_transactions
  FROM dedup_visit
  GROUP BY channelGrouping, country
),
eligible_channels AS (          -- step 2: channel groupings active in >1 country
  SELECT channelGrouping
  FROM transactions_by_country
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),
ranked AS (                      -- step 3: rank countries inside each channel grouping
  SELECT
    t.channelGrouping,
    t.country,
    t.total_transactions,
    ROW_NUMBER() OVER (PARTITION BY t.channelGrouping
                       ORDER BY t.total_transactions DESC, t.country) AS rn
  FROM transactions_by_country t
  JOIN eligible_channels e
    ON t.channelGrouping = e.channelGrouping
)
SELECT
  channelGrouping,
  country   AS top_country,
  total_transactions AS top_country_transactions
FROM ranked
WHERE rn = 1
ORDER BY channelGrouping;