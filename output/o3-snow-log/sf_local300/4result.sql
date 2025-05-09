/*--------------------------------------------------------------------
  Step-1 : Find every customer’s first and last transaction dates
--------------------------------------------------------------------*/
WITH customer_bounds AS (
    SELECT
        "customer_id",
        MIN(TO_DATE("txn_date")) AS min_date,
        MAX(TO_DATE("txn_date")) AS max_date
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id"
),

/*--------------------------------------------------------------------
  Step-2 : Build a daily calendar between those dates
           (using ARRAY_GENERATE_RANGE + FLATTEN so the length may vary)
--------------------------------------------------------------------*/
calendar AS (
    SELECT
        cb."customer_id",
        DATEADD(
            day, 
            seq.value::INT,                 -- offset
            cb.min_date
        )            AS calendar_date
    FROM customer_bounds cb
    , LATERAL FLATTEN(
          INPUT => ARRAY_GENERATE_RANGE(
                       0,
                       DATEDIFF(day, cb.min_date, cb.max_date) + 1   -- inclusive
                   )
      ) seq
),

/*--------------------------------------------------------------------
  Step-3 : Net cash movement per customer-day
--------------------------------------------------------------------*/
daily_net AS (
    SELECT
        "customer_id",
        TO_DATE("txn_date") AS txn_date,
        SUM(
            CASE
                 WHEN LOWER("txn_type") LIKE '%deposit%'  THEN  "txn_amount"
                 WHEN LOWER("txn_type") LIKE '%withdraw%' THEN -1 * "txn_amount"
                 ELSE 0
            END
        ) AS net_amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id", TO_DATE("txn_date")
),

/*--------------------------------------------------------------------
  Step-4 : Attach (possibly NULL) net_amount to every calendar day
--------------------------------------------------------------------*/
calendar_net AS (
    SELECT
        c."customer_id",
        c.calendar_date,
        COALESCE(dn.net_amount, 0) AS net_amount
    FROM calendar c
    LEFT JOIN daily_net dn
           ON  c."customer_id" = dn."customer_id"
           AND c.calendar_date  = dn.txn_date
),

/*--------------------------------------------------------------------
  Step-5 : Running balance per customer
--------------------------------------------------------------------*/
running_balances AS (
    SELECT
        "customer_id",
        calendar_date,
        SUM(net_amount) OVER (
            PARTITION BY "customer_id"
            ORDER BY calendar_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM calendar_net
),

/*--------------------------------------------------------------------
  Step-6 : Floor negative balances to zero
--------------------------------------------------------------------*/
daily_balances AS (
    SELECT
        "customer_id",
        calendar_date,
        CASE WHEN running_balance < 0 THEN 0 ELSE running_balance END AS daily_balance
    FROM running_balances
),

/*--------------------------------------------------------------------
  Step-7 : Highest daily balance per customer & month
--------------------------------------------------------------------*/
cust_month_max AS (
    SELECT
        "customer_id",
        TO_CHAR(calendar_date, 'YYYY-MM') AS year_month,
        MAX(daily_balance)                AS max_daily_balance
    FROM daily_balances
    GROUP BY "customer_id", TO_CHAR(calendar_date, 'YYYY-MM')
)

/*--------------------------------------------------------------------
  Step-8 : Monthly total of those customer-level maxima
--------------------------------------------------------------------*/
SELECT
    year_month,
    SUM(max_daily_balance) AS total_monthly_max_balance
FROM cust_month_max
GROUP BY year_month
ORDER BY year_month NULLS LAST;