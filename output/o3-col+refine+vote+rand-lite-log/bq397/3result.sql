-- Top-performing country (by transactions) for every multi-country channel grouping
WITH dedup AS (         -- 1.  De-duplicate visit-level rows
  SELECT DISTINCT
    fullVisitorId,
    visitId,
    channelGrouping,
    geoNetwork_country        AS country,
    totals_transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE totals_transactions IS NOT NULL
),

agg AS (                -- 2.  Aggregate transactions by channel & country
  SELECT
    channelGrouping,
    country,
    SUM(totals_transactions) AS transactions_sum
  FROM dedup
  GROUP BY channelGrouping, country
),

multi_country AS (      -- 3.  Keep channel groupings present in >1 country
  SELECT channelGrouping
  FROM agg
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),

ranked AS (             -- 4.  Rank countries within each qualifying channel
  SELECT
    a.channelGrouping,
    a.country,
    a.transactions_sum,
    ROW_NUMBER() OVER (PARTITION BY a.channelGrouping
                       ORDER BY a.transactions_sum DESC) AS rn
  FROM agg AS a
  JOIN multi_country AS m
  ON  a.channelGrouping = m.channelGrouping
)

-- 5.  Return the top country per eligible channel grouping
SELECT
  channelGrouping,
  country        AS top_country,
  transactions_sum AS top_transactions
FROM ranked
WHERE rn = 1
ORDER BY channelGrouping;