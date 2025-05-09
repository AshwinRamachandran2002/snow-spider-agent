/*  Channel‑level top‑country (by transactions) after de‑duplicating rev_transactions  */

WITH dedup AS (   -- keep only one record per visit (transaction)
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    visitId,
    ANY_VALUE(totals_transactions) AS transactions      -- transactions for that visit
  FROM `data-to-insights.ecommerce.rev_transactions`
  GROUP BY
    channelGrouping,
    country,
    visitId
),

country_txn AS (   -- total transactions per channel / country
  SELECT
    channelGrouping,
    country,
    SUM(IFNULL(transactions,0)) AS total_transactions
  FROM dedup
  GROUP BY
    channelGrouping,
    country
),

multi_country_channels AS (   -- channels that operate in >1 country
  SELECT
    channelGrouping
  FROM country_txn
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),

ranked AS (   -- rank countries within each qualifying channel
  SELECT
    c.channelGrouping,
    c.country,
    c.total_transactions,
    ROW_NUMBER() OVER (PARTITION BY c.channelGrouping
                       ORDER BY c.total_transactions DESC) AS rn
  FROM country_txn c
  JOIN multi_country_channels m
    ON c.channelGrouping = m.channelGrouping
)

SELECT
  channelGrouping,
  country,
  total_transactions
FROM ranked
WHERE rn = 1               -- top country per channel
ORDER BY channelGrouping;