-- For every channel grouping that records transactions in more than one country,
-- return the country with the highest summed transactions (after de-duplicating visitor-visit pairs).
WITH clean AS (
  -- 1.  De-duplicate rows (one per visitor-visit) and keep only rows that have transactions.
  SELECT DISTINCT
    `fullVisitorId`,
    `visitId`,
    `channelGrouping`,
    `geoNetwork_country`           AS country,
    `totals_transactions`          AS transactions
  FROM
    `data-to-insights.ecommerce.rev_transactions`
  WHERE
    `totals_transactions` IS NOT NULL
),
agg AS (
  -- 2.  Aggregate total transactions by (channelGrouping , country).
  SELECT
    channelGrouping,
    country,
    SUM(transactions) AS total_transactions
  FROM
    clean
  GROUP BY
    channelGrouping, country
),
multi_country_grps AS (
  -- 3.  Keep only the channel groupings that appear in more than one country.
  SELECT
    channelGrouping
  FROM
    agg
  GROUP BY
    channelGrouping
  HAVING
    COUNT(DISTINCT country) > 1
),
ranked AS (
  -- 4.  Rank countries within each qualifying channel grouping by total transactions.
  SELECT
    a.*,
    ROW_NUMBER() OVER (
      PARTITION BY a.channelGrouping
      ORDER BY     a.total_transactions DESC
    ) AS rn
  FROM
    agg AS a
  JOIN
    multi_country_grps USING (channelGrouping)
)

-- 5.  Final result: highest-transaction country for each multi-country channel grouping.
SELECT
  channelGrouping,
  country,
  total_transactions
FROM
  ranked
WHERE
  rn = 1
ORDER BY
  channelGrouping;