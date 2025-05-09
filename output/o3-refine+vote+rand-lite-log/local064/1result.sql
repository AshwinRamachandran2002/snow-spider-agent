WITH month_net AS (
    /* 1.  Net (month‑end) balance for every customer for every month of 2020 */
    SELECT
        "customer_id",
        substr("txn_date", 1, 7)           AS month_yyyy_mm,          -- e.g. 2020‑01
        SUM(
              CASE WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                   WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                   ELSE 0
              END
        )                                 AS month_end_balance
    FROM   "customer_transactions"
    WHERE  substr("txn_date", 1, 4) = '2020'
    GROUP  BY "customer_id", month_yyyy_mm
),
positive_cnt AS (
    /* 2.  Number of customers whose month‑end balance is positive, per month */
    SELECT
        month_yyyy_mm,
        SUM(CASE WHEN month_end_balance > 0 THEN 1 ELSE 0 END) 
            AS positive_customer_cnt
    FROM   month_net
    GROUP  BY month_yyyy_mm
),
hi_month AS (
    /* 3.  Month with the HIGHEST count of positive‑balance customers */
    SELECT  month_yyyy_mm
    FROM    positive_cnt
    ORDER BY positive_customer_cnt DESC, month_yyyy_mm      -- tie‑break by month
    LIMIT   1
),
lo_month AS (
    /* 4.  Month with the LOWEST count of positive‑balance customers */
    SELECT  month_yyyy_mm
    FROM    positive_cnt
    ORDER BY positive_customer_cnt ASC,  month_yyyy_mm      -- tie‑break by month
    LIMIT   1
),
avg_bal AS (
    /* 5.  Average month‑end balance for both identified months */
    SELECT
        month_yyyy_mm,
        AVG(month_end_balance) AS avg_month_end_balance
    FROM   month_net
    WHERE  month_yyyy_mm IN (SELECT month_yyyy_mm FROM hi_month
                             UNION
                             SELECT month_yyyy_mm FROM lo_month)
    GROUP  BY month_yyyy_mm
)
SELECT
    (SELECT month_yyyy_mm FROM hi_month)                    AS highest_positive_month,
    (SELECT avg_month_end_balance FROM avg_bal
        WHERE month_yyyy_mm = (SELECT month_yyyy_mm FROM hi_month))
                                                           AS highest_month_avg_balance,
    (SELECT month_yyyy_mm FROM lo_month)                    AS lowest_positive_month,
    (SELECT avg_month_end_balance FROM avg_bal
        WHERE month_yyyy_mm = (SELECT month_yyyy_mm FROM lo_month))
                                                           AS lowest_month_avg_balance,
    /* 6.  Difference between the two averages */
    ( (SELECT avg_month_end_balance FROM avg_bal
         WHERE month_yyyy_mm = (SELECT month_yyyy_mm FROM hi_month))
      -
      (SELECT avg_month_end_balance FROM avg_bal
         WHERE month_yyyy_mm = (SELECT month_yyyy_mm FROM lo_month))
    )                                                      AS average_balance_difference;