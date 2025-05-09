/* Conversion rate & average transactions per purchaser
   using only ECOMMERCE.ECOMMERCE.WEB_ANALYTICS            */

WITH visitor_stats AS (   -- one row per visitor
    SELECT
        "fullVisitorId"                                                      AS visitor_id,
        SUM( COALESCE( TRY_TO_NUMBER( ("totals":"transactions")::STRING ), 0) )  AS total_transactions
    FROM  ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
    GROUP BY "fullVisitorId"
),
overall AS (            -- counts of visitors & purchasers
    SELECT
        COUNT(*)                                                    AS total_unique_visitors,
        SUM( CASE WHEN total_transactions > 0 THEN 1 ELSE 0 END )  AS unique_purchasers
    FROM visitor_stats
),
avg_txn AS (            -- average transactions per purchaser
    SELECT
        AVG( total_transactions ) AS avg_transactions_per_purchaser
    FROM visitor_stats
    WHERE total_transactions > 0
)

SELECT
    o.total_unique_visitors,
    o.unique_purchasers,
    o.unique_purchasers::FLOAT / NULLIF( o.total_unique_visitors , 0 )  AS conversion_rate,
    a.avg_transactions_per_purchaser
FROM overall  o
CROSS JOIN avg_txn a;