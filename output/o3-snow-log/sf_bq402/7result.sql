/*----------------------------------------------------------
  Conversion rate & average number of transactions per purchaser
  using ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
----------------------------------------------------------*/
WITH visitor_txn AS (          -- 1 row per visitor with total transactions
    SELECT
        "fullVisitorId"                                                              AS visitor_id ,
        SUM( COALESCE( ("totals":"transactions")::NUMBER , 0 ) )                     AS total_transactions
    FROM  ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
    GROUP BY "fullVisitorId"
),
agg AS (                       -- aggregate metrics
    SELECT
        COUNT(*)                                              AS unique_visitors ,                         -- all visitors
        COUNT(CASE WHEN total_transactions > 0 THEN 1 END)    AS purchasers ,                              -- visitors with ≥1 txn
        AVG( CASE WHEN total_transactions > 0                                                     -- average txn / purchaser
                  THEN total_transactions END )              AS avg_transactions_per_purchaser
    FROM visitor_txn
)
SELECT
    unique_visitors ,
    purchasers ,
    CAST(purchasers AS FLOAT) / NULLIF(unique_visitors , 0)   AS conversion_rate ,        -- purchasers / visitors
    avg_transactions_per_purchaser
FROM agg;