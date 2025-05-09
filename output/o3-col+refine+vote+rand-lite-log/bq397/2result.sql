-- FINAL ANSWER
-- 1️⃣  Deduplicate the source by keeping one row per
--     (channelGrouping, country, transaction id).
WITH dedup AS (
  SELECT DISTINCT
    channelGrouping,
    geoNetwork_country        AS country,
    hits_transaction_transactionId AS txn_id,
    totals_transactions
  FROM `data-to-insights.ecommerce.rev_transactions`
  WHERE hits_transaction_transactionId IS NOT NULL      -- keep only rows that have a txn id
),

-- 2️⃣  Aggregate the (already deduplicated) rows to get the
--     total number of transactions per (channelGrouping, country).
country_txns AS (
  SELECT
    channelGrouping,
    country,
    SUM(totals_transactions) AS total_transactions
  FROM dedup
  GROUP BY channelGrouping, country
),

-- 3️⃣  Keep only the channel groupings that appear in more than
--     one country.
multi_country_channels AS (
  SELECT
    channelGrouping
  FROM country_txns
  GROUP BY channelGrouping
  HAVING COUNT(DISTINCT country) > 1
),

-- 4️⃣  Rank countries within each channelGrouping by their
--     total number of transactions.
ranked AS (
  SELECT
    ct.channelGrouping,
    ct.country,
    ct.total_transactions,
    RANK() OVER (
      PARTITION BY ct.channelGrouping
      ORDER BY ct.total_transactions DESC
    ) AS rnk
  FROM country_txns ct
  JOIN multi_country_channels mc
    ON ct.channelGrouping = mc.channelGrouping
)

-- 5️⃣  Return the top-country for each qualifying channelGrouping.
SELECT
  channelGrouping,
  country  AS top_country_by_txns,
  total_transactions
FROM ranked
WHERE rnk = 1
ORDER BY channelGrouping;