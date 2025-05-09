-- FINAL ANSWER
-- 1. De-duplicate the revenue table
-- 2. Keep only rows with a transaction count
-- 3. Keep only channel groupings that have transactions coming from >1 country
-- 4. For every such channel, aggregate total transactions per country
-- 5. Pick the country with the largest number of transactions per channel

WITH clean AS (
  SELECT DISTINCT
         channelGrouping,
         geoNetwork_country AS country,
         totals_transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE totals_transactions IS NOT NULL                           -- keep rows that actually have transactions
),

multi_country_channels AS (                                       -- channels operating in >1 country
  SELECT channelGrouping
  FROM clean
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),

tx_per_channel_country AS (                                       -- total transactions per channel / country
  SELECT
    channelGrouping,
    country,
    SUM(totals_transactions) AS total_transactions
  FROM clean
  GROUP BY channelGrouping, country
  HAVING channelGrouping IN (SELECT channelGrouping
                             FROM multi_country_channels)
),

ranked AS (                                                       -- rank countries within each channel
  SELECT
    channelGrouping,
    country,
    total_transactions,
    ROW_NUMBER() OVER (PARTITION BY channelGrouping
                       ORDER BY total_transactions DESC) AS rnk
  FROM tx_per_channel_country
)

SELECT
  channelGrouping,
  country,
  total_transactions
FROM ranked
WHERE rnk = 1                                                     -- top-performing country per channel
ORDER BY channelGrouping;