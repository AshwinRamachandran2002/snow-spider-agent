-- For each channelGrouping that records transactions coming from
-- more than one country, return the country that contributes the
-- most transactions together with the summed transaction count.
WITH deduplicated AS (
  -- Remove duplicates that arise from the same visit being listed
  -- multiple times (e.g., one row per product hit).  DISTINCT on
  -- the key fields keeps only one row per (visitor, visit, country,
  -- channelGrouping, transactions) combination.
  SELECT DISTINCT
         channelGrouping,
         geoNetwork_country               AS country,
         totals_transactions              AS transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE totals_transactions IS NOT NULL          -- keep rows that actually have transactions
),

country_totals AS (
  -- Aggregate transactions by channel and country
  SELECT
    channelGrouping,
    country,
    SUM(transactions)                         AS total_transactions
  FROM deduplicated
  GROUP BY channelGrouping, country
),

ranked AS (
  -- Determine how many countries each channelGrouping spans, and rank
  -- countries within a channel by their transaction total
  SELECT
    channelGrouping,
    country,
    total_transactions,
    COUNT(DISTINCT country) OVER (PARTITION BY channelGrouping)        AS countries_in_channel,
    ROW_NUMBER()           OVER (PARTITION BY channelGrouping
                                 ORDER BY total_transactions DESC)     AS rn
  FROM country_totals
)

-- Pick channels that span multiple countries and keep the top‑country row
SELECT
  channelGrouping,
  country,
  total_transactions
FROM ranked
WHERE countries_in_channel > 1   -- channels active in more than one country
  AND rn = 1                     -- country with highest total transactions
ORDER BY channelGrouping;