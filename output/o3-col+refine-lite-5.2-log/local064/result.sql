WITH month_balances AS (                      -- net balance per customer & month
    SELECT  "customer_id",
            substr("txn_date",1,7)               AS "month_yyyy_mm",
            SUM(CASE
                    WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                    WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                    ELSE 0
                END)                             AS "balance"
    FROM    "customer_transactions"
    WHERE   "txn_date" LIKE '2020-%'
    GROUP   BY "customer_id", substr("txn_date",1,7)
),
positive_counts AS (                           -- # customers with positive balance
    SELECT  "month_yyyy_mm",
            COUNT(*)                            AS "positive_customer_cnt"
    FROM    month_balances
    WHERE   "balance" > 0
    GROUP   BY "month_yyyy_mm"
),
max_min AS (                                   -- months with most / fewest positives
    SELECT  (SELECT "month_yyyy_mm"
             FROM   positive_counts
             ORDER  BY "positive_customer_cnt" DESC, "month_yyyy_mm"
             LIMIT  1)                         AS month_most_positive,
            (SELECT "month_yyyy_mm"
             FROM   positive_counts
             ORDER  BY "positive_customer_cnt" ASC, "month_yyyy_mm"
             LIMIT  1)                         AS month_least_positive
),
avg_balances AS (                              -- average balance for those months
    SELECT  ROUND(AVG(CASE WHEN "month_yyyy_mm" = (SELECT month_most_positive  FROM max_min) 
                           THEN "balance" END), 4) AS avg_max,
            ROUND(AVG(CASE WHEN "month_yyyy_mm" = (SELECT month_least_positive FROM max_min) 
                           THEN "balance" END), 4) AS avg_min
    FROM    month_balances
)
SELECT  mm.month_most_positive,
        mm.month_least_positive,
        ab.avg_max,
        ab.avg_min,
        ROUND(ab.avg_max - ab.avg_min, 4) AS difference_between_avgs
FROM    max_min        AS mm
CROSS JOIN avg_balances AS ab;