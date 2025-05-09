-- Conversion rate & average transactions per purchaser
WITH base AS (
  -- one row per visitor with their (possible) transaction count
  SELECT DISTINCT
         fullVisitorId,
         SAFE_CAST(totals.transactions AS INT64) AS transactions
  FROM   `data-to-insights.ecommerce.web_analytics`
),
purchasers AS (
  -- keep only visitors that made ≥1 transaction
  SELECT
         fullVisitorId,
         SUM(transactions) AS total_transactions
  FROM   base
  WHERE  transactions IS NOT NULL
     AND transactions > 0
  GROUP  BY fullVisitorId
)

SELECT
  -- KPI 1: how many unique purchasers
  (SELECT COUNT(*) FROM purchasers)                                         AS unique_purchasers,
  -- KPI 2: how many unique visitors
  (SELECT COUNT(*) FROM base)                                               AS unique_visitors,
  -- KPI 3: conversion rate = purchasers / visitors
  ROUND( (SELECT COUNT(*) FROM purchasers) /
         (SELECT COUNT(*) FROM base) , 4)                                   AS conversion_rate,
  -- KPI 4: average number of transactions per purchaser
  ROUND( (SELECT AVG(total_transactions) FROM purchasers) , 4)              AS avg_transactions_per_purchaser
;