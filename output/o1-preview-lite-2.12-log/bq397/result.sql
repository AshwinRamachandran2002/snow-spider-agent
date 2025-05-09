WITH deduplicated AS (
  SELECT DISTINCT fullVisitorId, visitId, channelGrouping, geoNetwork_country, totals_transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE totals_transactions IS NOT NULL
    AND totals_transactions > 0
    AND channelGrouping IS NOT NULL
    AND geoNetwork_country IS NOT NULL
),
channel_groupings_with_multiple_countries AS (
  SELECT channelGrouping
  FROM deduplicated
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT geoNetwork_country) > 1
),
transactions_by_channel_country AS (
  SELECT channelGrouping, geoNetwork_country, SUM(totals_transactions) AS total_transactions
  FROM deduplicated
  WHERE channelGrouping IN (SELECT channelGrouping FROM channel_groupings_with_multiple_countries)
  GROUP BY channelGrouping, geoNetwork_country
),
ranked_transactions AS (
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    total_transactions,
    ROW_NUMBER() OVER (PARTITION BY channelGrouping ORDER BY total_transactions DESC) AS rank
  FROM transactions_by_channel_country
)
SELECT channelGrouping, country, total_transactions
FROM ranked_transactions
WHERE rank = 1;