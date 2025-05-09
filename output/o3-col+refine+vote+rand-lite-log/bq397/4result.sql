/* After de-duplicating `rev_transactions`, pick – for every channelGrouping
   that spans more than one country – the country with the highest summed
   transactions. */
WITH dedup AS (                         -- 1. remove exact-row duplicates
  SELECT DISTINCT *
  FROM `data-to-insights.ecommerce.rev_transactions`
),
country_tx AS (                         -- 2. sum transactions per channel & country
  SELECT
    channelGrouping,
    geoNetwork_country AS country,
    SUM(totals_transactions) AS total_tx
  FROM dedup
  GROUP BY 1,2
),
multi_country AS (                      -- 3. keep channels seen in >1 country
  SELECT channelGrouping
  FROM country_tx
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
)
SELECT                                   -- 4. final answer
  channelGrouping,
  country,
  total_tx
FROM country_tx
WHERE channelGrouping IN (SELECT channelGrouping FROM multi_country)
QUALIFY total_tx = MAX(total_tx) OVER (PARTITION BY channelGrouping)
ORDER BY channelGrouping;