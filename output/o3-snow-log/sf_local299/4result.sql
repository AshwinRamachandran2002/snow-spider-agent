/*---------------------------------------------------------------
  30-DAY MAX ROLLING-AVERAGE BALANCE (EXCLUDING BASELINE MONTH)
----------------------------------------------------------------*/
WITH base AS (   /* 1.  Sign the amounts & cast the date column */
    SELECT
        "customer_id",
        TO_DATE("txn_date", 'YYYY-MM-DD')           AS "txn_dt",
        CASE WHEN "txn_type" = 'deposit'
             THEN  "txn_amount"
             ELSE - "txn_amount"
        END                                         AS "signed_amount"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
), running_bal AS (   /* 2.  Daily running balance per customer */
    SELECT
        "customer_id",
        "txn_dt",
        SUM("signed_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY     "txn_dt"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "running_balance"
    FROM base
), rolling_avg AS (   /* 3.  30-day rolling average (negatives → 0) */
    SELECT
        "customer_id",
        "txn_dt",
        GREATEST(
            0,
            AVG("running_balance") OVER (
                PARTITION BY "customer_id"
                ORDER BY     "txn_dt"
                RANGE BETWEEN INTERVAL '29 DAY' PRECEDING AND CURRENT ROW
            )
        ) AS "avg_30day_balance"
    FROM running_bal
    /* keep rows after at least 30 days of history */
    QUALIFY DATEDIFF(
                'day',
                MIN("txn_dt") OVER (PARTITION BY "customer_id"),
                "txn_dt"
            ) >= 29
), customer_month_max AS (  /* 4.  Max 30-day avg per customer & month */
    SELECT
        "customer_id",
        TO_VARCHAR(DATE_TRUNC('month', "txn_dt"), 'YYYY-MM') AS "year_month",
        MAX("avg_30day_balance")                             AS "max_30day_balance"
    FROM rolling_avg
    GROUP BY "customer_id", DATE_TRUNC('month', "txn_dt")
), baseline AS (            /* 5.  First month (baseline) for each customer */
    SELECT
        "customer_id",
        TO_VARCHAR(
            DATE_TRUNC(
                'month',
                MIN(TO_DATE("txn_date", 'YYYY-MM-DD'))
            ),
            'YYYY-MM'
        ) AS "baseline_month"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id"
)
/*---------------------------------------------------------------
  6.  Sum the customer-level maxima per month (exclude baseline)
----------------------------------------------------------------*/
SELECT
    cmm."year_month",
    SUM(cmm."max_30day_balance") AS "monthly_total_max_30day_balance"
FROM customer_month_max cmm
JOIN baseline            b
  ON cmm."customer_id" = b."customer_id"
WHERE cmm."year_month" <> b."baseline_month"
GROUP BY cmm."year_month"
ORDER BY cmm."year_month";