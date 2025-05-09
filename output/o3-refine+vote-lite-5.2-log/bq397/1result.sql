-- Country with the highest number of transactions for every
-- channelGrouping that records transactions in more than one country
WITH per_visit AS (
  -- one row per visit to remove duplicated hit / product rows
  SELECT
    channelGrouping,
    geoNetwork_country      AS country,
    visitId,
    MAX(IFNULL(totals_transactions,0)) AS transactions_in_visit          -- usually 1
  FROM `data-to-insights.ecommerce.rev_transactions`
  GROUP BY channelGrouping, geoNetwork_country, visitId
),
channel_country_tx AS (
  -- total transactions per (channelGrouping , country)
  SELECT
    channelGrouping,
    country,
    SUM(transactions_in_visit) AS transactions
  FROM per_visit
  GROUP BY channelGrouping, country
),
channel_multi_country AS (
  -- keep only channelGroupings present in more than one country
  SELECT channelGrouping
  FROM channel_country_tx
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),
ranked AS (
  -- rank countries inside each eligible channelGrouping by transactions
  SELECT
    c.channelGrouping,
    c.country,
    c.transactions,
    ROW_NUMBER() OVER (PARTITION BY c.channelGrouping
                       ORDER BY c.transactions DESC, c.country) AS rn
  FROM channel_country_tx c
  JOIN channel_multi_country m
  ON c.channelGrouping = m.channelGrouping
)
SELECT
  channelGrouping,
  country  AS top_country,
  transactions AS top_country_transactions
FROM ranked
WHERE rn = 1
ORDER BY channelGrouping;