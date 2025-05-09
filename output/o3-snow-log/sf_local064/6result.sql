/* 1.  Calculate the month-end balance per customer for every month in 2020
   2.  Work out, per month, how many customers finished the month with a positive balance
   3.  Find the month with the most such customers and the month with the fewest
   4.  For those two months, return the average month-end balance and the difference
*/
WITH txn_2020 AS (   -- all 2020 transactions with signed amounts (+deposit / –withdrawal)
    SELECT
        "customer_id",
        TO_CHAR(TO_DATE("txn_date", 'YYYY-MM-DD'), 'YYYY-MM')                    AS "year_month",
        CASE 
            WHEN LOWER("txn_type") = 'deposit'     THEN  "txn_amount"
            WHEN LOWER("txn_type") = 'withdrawal'  THEN - "txn_amount"
            ELSE 0
        END                                                                     AS "signed_amt"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
    WHERE TO_CHAR(TO_DATE("txn_date", 'YYYY-MM-DD'), 'YYYY') = '2020'
), monthly_balance AS (   -- month-end (net) balance for each customer/month
    SELECT
        "customer_id",
        "year_month",
        SUM("signed_amt")                           AS "month_end_balance"
    FROM txn_2020
    GROUP BY 1, 2
), month_stats AS (      -- statistics per month
    SELECT
        "year_month",
        COUNT_IF("month_end_balance" > 0)           AS "positive_cust_cnt",
        AVG("month_end_balance")                    AS "avg_balance"
    FROM monthly_balance
    GROUP BY "year_month"
), ranked AS (          -- rank months by # positive customers
    SELECT
        *,
        RANK() OVER (ORDER BY "positive_cust_cnt" DESC) AS "rank_high",
        RANK() OVER (ORDER BY "positive_cust_cnt" ASC)  AS "rank_low"
    FROM month_stats
)
SELECT
    MAX(CASE WHEN "rank_high" = 1 THEN "year_month"       END) AS "month_with_most_positive_customers",
    MAX(CASE WHEN "rank_high" = 1 THEN "positive_cust_cnt" END) AS "highest_positive_customer_count",
    MAX(CASE WHEN "rank_high" = 1 THEN "avg_balance"       END) AS "avg_balance_high",
    
    MAX(CASE WHEN "rank_low"  = 1 THEN "year_month"        END) AS "month_with_least_positive_customers",
    MAX(CASE WHEN "rank_low"  = 1 THEN "positive_cust_cnt" END) AS "lowest_positive_customer_count",
    MAX(CASE WHEN "rank_low"  = 1 THEN "avg_balance"       END) AS "avg_balance_low",
    
    MAX(CASE WHEN "rank_high" = 1 THEN "avg_balance" END)
  - MAX(CASE WHEN "rank_low"  = 1 THEN "avg_balance" END)     AS "difference_between_averages"
FROM ranked;