WITH deduped AS (
  SELECT DISTINCT
    fullVisitorId,
    visitId,
    channelGrouping,
    geoNetwork_country,
    totals_transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
),
grouped AS (
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    SUM(totals_transactions) AS total_transactions
  FROM deduped
  GROUP BY channelGrouping, country
),
multi_country_channels AS (
  SELECT
    channelGrouping
  FROM grouped
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),
ranked AS (
  SELECT
    channelGrouping,
    country,
    total_transactions,
    ROW_NUMBER() OVER (
      PARTITION BY channelGrouping
      ORDER BY total_transactions DESC
    ) AS rn
  FROM grouped
  WHERE channelGrouping IN (SELECT channelGrouping FROM multi_country_channels)
)
SELECT
  channelGrouping,
  country,
  total_transactions
FROM ranked
WHERE rn = 1;