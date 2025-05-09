-- 1) de‑duplicate the rev_transactions table at the level of one
--    transaction (visitId) inside a channel / country pair
-- 2) keep only channel groupings that have transactions coming
--    from more than one country
-- 3) for every such channel grouping, return the country that
--    contributes the largest number of transactions together with
--    that sum
WITH dedup AS (         -- remove duplicate rows
  SELECT DISTINCT
         channelGrouping,
         geoNetwork_country           AS country,
         visitId,                     -- one transaction session
         totals_transactions          -- usually 1 per visitId
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE totals_transactions IS NOT NULL            -- keep only rows with a transaction
        AND geoNetwork_country IS NOT NULL         -- ignore missing country values
),
country_tx AS (        -- total transactions per channel & country
  SELECT
    channelGrouping,
    country,
    SUM(totals_transactions) AS total_transactions
  FROM dedup
  GROUP BY channelGrouping, country
),
multi_country_channels AS (     -- channels present in >1 country
  SELECT channelGrouping
  FROM country_tx
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),
ranked AS (    -- pick top‑country per channel
  SELECT
    ct.channelGrouping,
    ct.country,
    ct.total_transactions,
    ROW_NUMBER() OVER (PARTITION BY ct.channelGrouping
                       ORDER BY ct.total_transactions DESC, ct.country) AS rn
  FROM country_tx ct
  JOIN multi_country_channels mc
  USING (channelGrouping)
)
SELECT
  channelGrouping,
  country,
  total_transactions
FROM ranked
WHERE rn = 1          -- keep only the country with the most transactions
ORDER BY channelGrouping;