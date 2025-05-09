WITH transactions_per_country AS (
  SELECT 
    channelGrouping,
    country,
    SUM(transactions) AS total_transactions
  FROM `data-to-insights.ecommerce.all_sessions`
  WHERE transactions > 0
  GROUP BY channelGrouping, country
),
channels_with_multiple_countries AS (
  SELECT
    channelGrouping
  FROM transactions_per_country
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),
transactions_ranked AS (
  SELECT
    tpc.channelGrouping,
    tpc.country,
    tpc.total_transactions,
    ROW_NUMBER() OVER (
      PARTITION BY tpc.channelGrouping 
      ORDER BY tpc.total_transactions DESC
    ) AS rn
  FROM transactions_per_country tpc
  WHERE tpc.channelGrouping IN (SELECT channelGrouping FROM channels_with_multiple_countries)
)
SELECT
  channelGrouping AS ChannelGrouping,
  country AS Country,
  total_transactions AS TotalTransactions
FROM transactions_ranked
WHERE rn = 1
ORDER BY channelGrouping;