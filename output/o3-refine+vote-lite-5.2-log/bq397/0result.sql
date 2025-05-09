/*  For every channelGrouping that has transactions coming from more than one
    country, return the country with the highest total number of transactions
    together with that total.
*/
WITH deduplicated AS (          -- one row per GA visit / transaction
  SELECT DISTINCT
         fullVisitorId,
         visitId,
         channelGrouping,
         geoNetwork_country,
         totals_transactions
  FROM  `data-to-insights.ecommerce.rev_transactions`
  WHERE totals_transactions IS NOT NULL
),
tx_by_country AS (             -- aggregate transactions by channel & country
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    SUM(totals_transactions) AS total_transactions
  FROM deduplicated
  GROUP BY channelGrouping, country
),
multi_country_channels AS (    -- keep only channels having >1 country
  SELECT
    t.*,
    COUNT(DISTINCT country) OVER (PARTITION BY channelGrouping) AS num_countries
  FROM tx_by_country t
),
ranked AS (                    -- rank countries inside each channel by volume
  SELECT
    channelGrouping,
    country,
    total_transactions,
    ROW_NUMBER() OVER (PARTITION BY channelGrouping
                       ORDER BY total_transactions DESC) AS rn
  FROM multi_country_channels
  WHERE num_countries > 1
)
SELECT
  channelGrouping,
  country,
  total_transactions
FROM ranked
WHERE rn = 1
ORDER BY channelGrouping;