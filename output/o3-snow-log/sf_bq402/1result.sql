WITH visitor_transactions AS (
    SELECT
        "fullVisitorId",
        /* sum of all transactions recorded for this visitor (0 if none) */
        SUM( COALESCE( ("totals":"transactions")::NUMBER , 0) ) AS total_transactions
    FROM ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
    GROUP BY "fullVisitorId"
)

SELECT
    COUNT(*)                                                             AS "unique_visitors",
    SUM(CASE WHEN total_transactions > 0 THEN 1 ELSE 0 END)              AS "purchasers",
    SUM(CASE WHEN total_transactions > 0 THEN 1 ELSE 0 END)::FLOAT
    / COUNT(*)                                                           AS "conversion_rate",
    AVG(CASE WHEN total_transactions > 0 THEN total_transactions END)     AS "avg_transactions_per_purchaser"
FROM visitor_transactions;