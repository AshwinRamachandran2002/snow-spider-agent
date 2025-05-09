/*------------------------------------------------------------
  1. Build a complete calendar for every customer
  2. Work out each day’s net movement  (+deposit , –withdrawal)
  3. Derive a running balance that never drops below 0
       balance(d) = max( 0 , balance(d-1) + net(d) )
     (achieved with running-sum trick shown below)
  4. For every customer/month pick the highest daily balance
  5. Sum those maxima across customers to obtain the
     monthly total requested
------------------------------------------------------------*/
WITH customer_bounds AS (   -- date span for every customer
    SELECT
        "customer_id",
        MIN(TO_DATE("txn_date")) AS min_date,
        MAX(TO_DATE("txn_date")) AS max_date
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id"
),
calendar AS (               -- day-by-day calendar per customer
    SELECT
        cb."customer_id",
        DATEADD(day, seq4(), cb.min_date) AS calendar_day
    FROM customer_bounds cb,
         TABLE(GENERATOR(ROWCOUNT => 36525)) g          -- big enough for 100-years
    WHERE seq4() <= DATEDIFF('day', cb.min_date, cb.max_date)
),
daily_net AS (              -- net cash-flow by customer/day
    SELECT
        "customer_id",
        TO_DATE("txn_date")           AS calendar_day,
        SUM(CASE
                WHEN LOWER("txn_type") LIKE '%deposit%'   THEN  "txn_amount"
                WHEN LOWER("txn_type") LIKE '%withdraw%'  THEN - "txn_amount"
                ELSE 0
            END)                     AS net_amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id", calendar_day
),
daily_series AS (           -- calendar + net (0 for no txn)
    SELECT
        c."customer_id",
        c.calendar_day,
        COALESCE(dn.net_amount, 0) AS net_amount
    FROM calendar c
    LEFT JOIN daily_net dn
           ON  c."customer_id" = dn."customer_id"
           AND c.calendar_day  = dn.calendar_day
),
running AS (                -- plain running sum of daily deltas
    SELECT
        "customer_id",
        calendar_day,
        net_amount,
        SUM(net_amount) OVER (
            PARTITION BY "customer_id"
            ORDER BY      calendar_day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sum
    FROM daily_series
),
clipped AS (                -- running minimum of that sum
    SELECT
        r.*,
        MIN(running_sum) OVER (
            PARTITION BY "customer_id"
            ORDER BY      calendar_day
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS min_running_sum
    FROM running r
),
balances AS (               -- non-negative daily balance
    SELECT
        "customer_id",
        calendar_day,
        /*  running_sum – min_running_sum(≤0)  */
        GREATEST(running_sum - LEAST(min_running_sum,0), 0) AS balance
    FROM clipped
),
monthly_max AS (            -- customer-level monthly peak
    SELECT
        "customer_id",
        TO_CHAR(calendar_day, 'YYYY-MM') AS month_year,
        MAX(balance)                     AS max_daily_balance
    FROM balances
    GROUP BY "customer_id", month_year
)
-- 6. Monthly total across all customers
SELECT
    month_year,
    SUM(max_daily_balance) AS monthly_total_balance
FROM monthly_max
GROUP BY month_year
ORDER BY month_year;