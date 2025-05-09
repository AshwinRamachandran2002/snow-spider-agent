/*-----------------------------------------------------------
  Conversion rate & average transactions per purchaser
  using only the WEB_ANALYTICS table
-----------------------------------------------------------*/
WITH web_data AS (     -- Extract visitor id and numeric transactions
    SELECT
        "fullVisitorId"                                          AS visitor_id,
        TRY_TO_NUMBER( ("totals":"transactions")::STRING )       AS transactions   -- NULL if absent
    FROM ECOMMERCE.ECOMMERCE."WEB_ANALYTICS"
),

visitors AS (          -- every unique visitor
    SELECT DISTINCT visitor_id
    FROM web_data
),

purchasers AS (        -- visitors with ≥1 transaction
    SELECT DISTINCT visitor_id
    FROM web_data
    WHERE transactions > 0
),

transactions_per_purchaser AS (   -- total transactions per purchasing visitor
    SELECT
        visitor_id,
        SUM(transactions) AS total_transactions
    FROM web_data
    WHERE transactions > 0
    GROUP BY visitor_id
)

SELECT
    /* conversion rate = unique purchasers / unique visitors */
    ROUND(
        (SELECT COUNT(*) FROM purchasers)::FLOAT
        / NULLIF( (SELECT COUNT(*) FROM visitors), 0)
    , 4) AS conversion_rate,

    /* average number of transactions per purchaser */
    ROUND(
        (SELECT AVG(total_transactions) FROM transactions_per_purchaser)
    , 4) AS avg_transactions_per_purchaser;