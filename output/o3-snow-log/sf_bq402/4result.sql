WITH visit_data AS (           /* pull visitor id and numeric transactions per session */
    SELECT
        "fullVisitorId"                                                AS visitor_id,
        TRY_TO_NUMBER( ("totals":"transactions")::STRING )             AS transactions
    FROM  ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
),
unique_counts AS (              /* total visitors and visitors who purchased */
    SELECT
        COUNT(DISTINCT visitor_id)                                                             AS total_unique_visitors,
        COUNT(DISTINCT CASE WHEN transactions IS NOT NULL AND transactions > 0 THEN visitor_id END)
                                                                                               AS unique_purchasers
    FROM visit_data
),
purchaser_txns AS (             /* total transactions for each purchasing visitor */
    SELECT
        visitor_id,
        SUM(transactions) AS total_transactions
    FROM visit_data
    WHERE transactions IS NOT NULL AND transactions > 0
    GROUP BY visitor_id
),
avg_txn AS (                    /* average number of transactions per purchaser */
    SELECT
        AVG(total_transactions) AS avg_transactions_per_purchaser
    FROM purchaser_txns
)
SELECT
    c.total_unique_visitors,
    c.unique_purchasers,
    c.unique_purchasers * 1.0 / NULLIF(c.total_unique_visitors,0)   AS conversion_rate,
    a.avg_transactions_per_purchaser
FROM unique_counts c
CROSS JOIN avg_txn a;