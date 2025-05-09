/*  Top-country (by transactions) for every channelGrouping that spans >1 country  */
WITH dedup AS (               -- 1. De-duplicate the raw rows
  SELECT DISTINCT
         channelGrouping,
         geoNetwork_country      AS country,
         totals_transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
),

agg AS (                       -- 2. Sum transactions per (channel , country)
  SELECT
    channelGrouping,
    country,
    SUM(IFNULL(totals_transactions,0)) AS total_transactions
  FROM dedup
  GROUP BY channelGrouping, country
),

ranked AS (                    -- 3. Rank countries inside each channelGrouping
  SELECT
    agg.*,
    ROW_NUMBER() OVER (PARTITION BY channelGrouping
                       ORDER BY total_transactions DESC)  AS rn,
    COUNT(*)    OVER (PARTITION BY channelGrouping)       AS country_cnt
  FROM agg
)

-- 4. Pick the #1 country for channelGroupings that operate in >1 country
SELECT
  channelGrouping,
  country,
  total_transactions
FROM ranked
WHERE rn = 1          -- top country
  AND country_cnt > 1 -- channelGrouping present in multiple countries
ORDER BY total_transactions DESC;