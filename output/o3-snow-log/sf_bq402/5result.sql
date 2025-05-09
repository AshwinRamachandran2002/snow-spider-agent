/*----------------------------------------------------------
  Conversion rate & average transactions per purchaser
  Source table : ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
----------------------------------------------------------*/
WITH visitor_transactions AS (
    SELECT
        "fullVisitorId"                                         AS visitor_id,
        SUM(
            COALESCE(
                TRY_TO_NUMBER( ( "totals":"transactions" )::STRING ),  -- safe numeric conversion
                0
            )
        )                                                       AS total_transactions
    FROM ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
    GROUP BY "fullVisitorId"
),
aggregated AS (
    SELECT
        COUNT(*)                                                AS total_visitors,
        SUM(CASE WHEN total_transactions > 0 THEN 1 ELSE 0 END) AS purchasers,
        SUM(CASE WHEN total_transactions > 0
                 THEN total_transactions ELSE 0 END)            AS transactions_from_purchasers
    FROM visitor_transactions
)
SELECT
    total_visitors,
    purchasers,
    ROUND(purchasers::FLOAT / NULLIF(total_visitors, 0), 4)          AS conversion_rate,
    ROUND(transactions_from_purchasers::FLOAT / NULLIF(purchasers, 0), 4)
                                                                    AS avg_transactions_per_purchaser
FROM aggregated;