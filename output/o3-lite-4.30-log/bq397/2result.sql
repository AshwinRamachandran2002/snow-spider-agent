WITH session_level AS (        -- deduplicate by unique session
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    SUM(SAFE_CAST(totals_transactions AS INT64)) AS transactions     -- transactions within the session
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE totals_transactions IS NOT NULL
  GROUP BY
    channelGrouping,
    country,
    fullVisitorId,
    visitId                     -- each (visitor, visit) pair = one session
),

agg AS (                        -- total transactions per (channel, country)
  SELECT
    channelGrouping,
    country,
    SUM(transactions) AS total_transactions
  FROM session_level
  GROUP BY channelGrouping, country
),

multi_country AS (              -- channels that exist in > 1 country
  SELECT channelGrouping
  FROM agg
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),

ranked AS (                     -- rank countries inside each qualifying channel
  SELECT
    a.channelGrouping,
    a.country,
    a.total_transactions,
    ROW_NUMBER() OVER (
      PARTITION BY a.channelGrouping
      ORDER BY a.total_transactions DESC, a.country
    ) AS rn
  FROM agg a
  JOIN multi_country m
  ON a.channelGrouping = m.channelGrouping
)

SELECT
  channelGrouping AS channel_grouping,
  country         AS top_country,
  total_transactions
FROM ranked
WHERE rn = 1
ORDER BY channel_grouping;