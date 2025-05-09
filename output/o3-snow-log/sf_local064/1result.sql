WITH txn AS (   -- 1. tag each transaction with + / - and keep only 2020
    SELECT  
        "customer_id",
        TO_DATE("txn_date",'YYYY-MM-DD')        AS txn_dt,
        CASE 
            WHEN LOWER("txn_type") = 'deposit'      THEN "txn_amount"
            ELSE                                        -1 * "txn_amount"
        END                                    AS amt
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    WHERE "txn_date" LIKE '2020-%'                         -- year 2020 only
),

cust_month AS (  -- 2. month-end balance per customer
    SELECT  
        "customer_id",
        TO_CHAR(DATE_TRUNC('month',txn_dt),'YYYY-MM')  AS month_yyyy_mm,
        SUM(amt)                                       AS month_end_balance
    FROM txn
    GROUP BY "customer_id", DATE_TRUNC('month',txn_dt)
),

month_stats AS (  -- 3. per-month stats
    SELECT  
        month_yyyy_mm,
        COUNT_IF(month_end_balance > 0)                AS positive_customer_count,
        AVG(month_end_balance)                         AS avg_month_end_balance
    FROM cust_month
    GROUP BY month_yyyy_mm
),

ranked AS (        -- 4. rank months by # positive customers
    SELECT  *,
            RANK() OVER(ORDER BY positive_customer_count DESC) AS pos_rank_desc,
            RANK() OVER(ORDER BY positive_customer_count ASC)  AS pos_rank_asc
    FROM    month_stats
),

selected AS (      -- 5. pull out the months with highest & lowest counts
    SELECT  
        MAX(CASE WHEN pos_rank_desc = 1 THEN month_yyyy_mm END)       AS month_high_positive,
        MAX(CASE WHEN pos_rank_desc = 1 THEN avg_month_end_balance END) AS avg_balance_high,
        MAX(CASE WHEN pos_rank_asc  = 1 THEN month_yyyy_mm END)       AS month_low_positive,
        MAX(CASE WHEN pos_rank_asc  = 1 THEN avg_month_end_balance END) AS avg_balance_low
    FROM ranked
)

SELECT  
    month_high_positive,
    avg_balance_high,
    month_low_positive,
    avg_balance_low,
    avg_balance_high - avg_balance_low                   AS difference_of_averages
FROM selected;