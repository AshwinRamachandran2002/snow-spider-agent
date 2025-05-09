SELECT
  channelGrouping AS ChannelGrouping,
  country AS Country,
  SUM(transactions) AS TotalTransactions
FROM `data-to-insights.ecommerce.all_sessions`
WHERE transactions > 0
GROUP BY channelGrouping, country
HAVING channelGrouping IN (
  SELECT channelGrouping
  FROM `data-to-insights.ecommerce.all_sessions`
  WHERE transactions > 0
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
)
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY channelGrouping
  ORDER BY SUM(transactions) DESC
) = 1