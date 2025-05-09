WITH RECURSIVE
-- 1.  Net cash-flow per customer per calendar day
daily_net AS (
    SELECT
        "customer_id",
        DATE("txn_date")                                    AS "txn_day",
        SUM(
            CASE WHEN "txn_type" = 'deposit'
                 THEN  "txn_amount"
                 ELSE - "txn_amount"
            END
        )                                                   AS "net_amount"
    FROM   "customer_transactions"
    GROUP  BY "customer_id", DATE("txn_date")
),

-- 2.  Span of days recorded for every customer
span AS (
    SELECT
        "customer_id",
        MIN("txn_day") AS "min_day",
        MAX("txn_day") AS "max_day"
    FROM   daily_net
    GROUP  BY "customer_id"
),

-- 3.  Build a complete day-by-day calendar for each customer
calendar("customer_id","cal_day") AS (
    SELECT  "customer_id", "min_day"
    FROM    span
    UNION ALL
    SELECT  c."customer_id",
            DATE(c."cal_day", '+1 day')
    FROM    calendar c
    JOIN    span     s
      ON    s."customer_id" = c."customer_id"
     AND    DATE(c."cal_day", '+1 day') <= s."max_day"
),

-- 4.  Daily balances (include idle days with zero net amount)
daily_bal AS (
    SELECT
        cal."customer_id",
        cal."cal_day",
        COALESCE(dn."net_amount", 0) AS "net_amount"
    FROM   calendar  cal
    LEFT  JOIN daily_net dn
           ON dn."customer_id" = cal."customer_id"
          AND dn."txn_day"     = cal."cal_day"
),

-- 5.  Running balance and day counter per customer
running_bal AS (
    SELECT
        db.*,
        SUM(db."net_amount") OVER (
            PARTITION BY db."customer_id"
            ORDER BY      db."cal_day"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                   AS "balance",
        ROW_NUMBER() OVER (
            PARTITION BY db."customer_id"
            ORDER BY      db."cal_day"
        )                                                   AS "rn"
    FROM   daily_bal db
),

-- 6.  30-day rolling average balance
rolling_avg AS (
    SELECT
        rb."customer_id",
        rb."cal_day",
        rb."rn",
        AVG(rb."balance") OVER (
            PARTITION BY rb."customer_id"
            ORDER BY      rb."cal_day"
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        )                                                   AS "avg_bal_30d"
    FROM   running_bal rb
),

-- 7.  Keep only rows after 30 full days; clamp negatives to zero
valid_avg AS (
    SELECT
        "customer_id",
        "cal_day",
        CASE WHEN "avg_bal_30d" < 0 THEN 0 ELSE "avg_bal_30d" END AS "avg_bal_30d_pos"
    FROM   rolling_avg
    WHERE  "rn" >= 30
),

-- 8.  Maximum 30-day average per customer & calendar month
month_max AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "cal_day") AS "year_month",
        MAX("avg_bal_30d_pos")       AS "max_30d_avg"
    FROM   valid_avg
    GROUP  BY "customer_id", strftime('%Y-%m', "cal_day")
),

-- 9.  Each customer’s baseline (first) transaction month
baseline AS (
    SELECT
        "customer_id",
        MIN("year_month") AS "first_month"
    FROM   month_max
    GROUP  BY "customer_id"
)

-- 10. Final report – sum of monthly maxima, excluding baseline month
SELECT
    mm."year_month",
    ROUND(SUM(mm."max_30d_avg"), 4) AS "sum_max_30d_avg_all_customers"
FROM   month_max mm
JOIN   baseline  b
  ON   b."customer_id" = mm."customer_id"
WHERE  mm."year_month" <> b."first_month"   -- omit baseline month
GROUP  BY mm."year_month"
ORDER  BY mm."year_month";