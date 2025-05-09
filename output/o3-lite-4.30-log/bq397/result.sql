WITH dedup AS (
  /* 1. De‑duplicate to one row per (fullVisitorId, visitId) that contains at least
        one transaction.  The values of channelGrouping and geoNetwork_country
        are constant within a session, so MAX() is safe to keep a single copy. */
  SELECT
    MAX(channelGrouping)        AS channelGrouping,
    MAX(geoNetwork_country)     AS country,
    MAX(totals_transactions)    AS transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE totals_transactions IS NOT NULL
  GROUP BY fullVisitorId, visitId
),
country_totals AS (
  /* 2. Total transactions for each (channel, country) pair */
  SELECT
    channelGrouping,
    country,
    SUM(transactions) AS total_transactions
  FROM dedup
  GROUP BY channelGrouping, country
),
multi_country_channels AS (
  /* 3. Keep only channels that have transactions in more than one country */
  SELECT channelGrouping
  FROM country_totals
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),
ranked AS (
  /* 4. Rank countries inside each eligible channel by total transactions */
  SELECT
    ct.channelGrouping,
    ct.country,
    ct.total_transactions,
    ROW_NUMBER() OVER (PARTITION BY ct.channelGrouping
                       ORDER BY ct.total_transactions DESC) AS rn
  FROM country_totals ct
  JOIN multi_country_channels mc
    ON ct.channelGrouping = mc.channelGrouping
)
/* 5. Return the top‑performing country for every qualifying channel */
SELECT
  channelGrouping   AS channel_grouping,
  country           AS top_country,
  total_transactions
FROM ranked
WHERE rn = 1
ORDER BY channel_grouping;