WITH month_bal AS (
    /* 1.  Compute each customer’s 2020 month-end balance                    */
    SELECT
           "customer_id",
           SUBSTR("txn_date",1,7)                         AS "month",
           SUM(CASE 
                   WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                   WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                   ELSE 0
               END)                                      AS "month_end_balance"
    FROM   "customer_transactions"
    WHERE  "txn_date" LIKE '2020-%'
      AND  "txn_type" IN ('deposit','withdrawal')
    GROUP  BY "customer_id", SUBSTR("txn_date",1,7)
),
pos_cnt AS (
    /* 2.  Count customers with a positive balance in each month            */
    SELECT "month",
           COUNT(*) AS "positive_cust_cnt"
    FROM   month_bal
    WHERE  "month_end_balance" > 0
    GROUP  BY "month"
),
high_month AS (
    /* 3a. Month with the greatest number of positive-balance customers     */
    SELECT "month"
    FROM   pos_cnt
    ORDER  BY "positive_cust_cnt" DESC, "month"
    LIMIT  1
),
low_month AS (
    /* 3b. Month with the fewest number of positive-balance customers       */
    SELECT "month"
    FROM   pos_cnt
    ORDER  BY "positive_cust_cnt" ASC, "month"
    LIMIT  1
),
month_avgs AS (
    /* 4.  Average month-end balance for the two identified months          */
    SELECT "month",
           AVG("month_end_balance") AS "avg_balance"
    FROM   month_bal
    WHERE  "month" IN (SELECT "month" FROM high_month
                       UNION
                       SELECT "month" FROM low_month)
    GROUP  BY "month"
)
SELECT
       MAX(CASE WHEN "month" = (SELECT "month" FROM high_month) THEN "avg_balance" END)
           AS "avg_balance_highest_cnt_month",
       MAX(CASE WHEN "month" = (SELECT "month" FROM low_month)  THEN "avg_balance" END)
           AS "avg_balance_lowest_cnt_month",
       MAX(CASE WHEN "month" = (SELECT "month" FROM high_month) THEN "avg_balance" END) -
       MAX(CASE WHEN "month" = (SELECT "month" FROM low_month)  THEN "avg_balance" END)
           AS "difference";