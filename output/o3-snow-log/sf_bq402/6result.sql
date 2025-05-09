/*-----------------------------------------------------------
  Conversion rate & average transactions per purchaser
  Data source : ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
-----------------------------------------------------------*/
WITH purchaser_txn AS (  -- visitors who generated ≥1 transaction
    SELECT
        "fullVisitorId"                                                    AS visitor_id ,
        SUM(
            COALESCE(
                TRY_TO_NUMBER( ("totals":"transactions")::STRING ) , 0
            )
        ) AS total_txn
    FROM ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
    GROUP BY "fullVisitorId"
    HAVING total_txn > 0
),
all_visitors AS (        -- total unique visitors
    SELECT COUNT( DISTINCT "fullVisitorId" ) AS n_visitors
    FROM   ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
)

SELECT
    v.n_visitors                                          AS total_unique_visitors ,
    p.n_purchasers                                        AS unique_purchasers ,
    ROUND( p.n_purchasers / v.n_visitors , 4 )            AS conversion_rate ,
    ROUND( p.avg_txn_per_purchaser , 4 )                  AS avg_transactions_per_purchaser
FROM   all_visitors v
CROSS  JOIN (
    SELECT
        COUNT(*)              AS n_purchasers ,
        AVG(total_txn)        AS avg_txn_per_purchaser
    FROM purchaser_txn
) p;