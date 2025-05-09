WITH orders_clean AS (   -- keep only valid (non‑cancelled) orders
    SELECT
        "user_id",
        TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) AS order_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" <> 'Cancelled'
      AND "user_id" IS NOT NULL
),
first_orders AS (        -- first purchase date of every customer
    SELECT
        "user_id",
        MIN(order_date) AS first_order_date
    FROM orders_clean
    GROUP BY "user_id"
),
cohort_users AS (        -- users whose first purchase happened in Jan‑2020
    SELECT "user_id"
    FROM first_orders
    WHERE first_order_date BETWEEN '2020-01-01' AND '2020-01-31'
),
cohort_size AS (         -- cohort size (constant)
    SELECT COUNT(*) AS cohort_cnt
    FROM cohort_users
),
subsequent_orders AS (   -- orders these users placed Feb‑Dec 2020
    SELECT
        oc."user_id",
        DATE_TRUNC('month', oc.order_date) AS order_month
    FROM orders_clean oc
    JOIN cohort_users cu
      ON oc."user_id" = cu."user_id"
    WHERE oc.order_date >= '2020-02-01'
      AND oc.order_date <  '2021-01-01'
),
monthly_retention AS (   -- distinct returning users per month
    SELECT
        order_month,
        COUNT(DISTINCT "user_id") AS returning_users
    FROM subsequent_orders
    GROUP BY order_month
),
all_months AS (          -- generate all months Feb‑Dec 2020 (so zeros appear)
    SELECT DATEADD(month, seq, '2020-02-01') AS order_month
    FROM (SELECT seq4() AS seq
          FROM TABLE(GENERATOR(ROWCOUNT => 11)))   -- Feb (0) … Dec (10)
)
SELECT
    TO_CHAR(am.order_month , 'YYYY-MM')        AS month,
    COALESCE(mr.returning_users , 0)           AS returning_users,
    cs.cohort_cnt                              AS cohort_size,
    ROUND(COALESCE(mr.returning_users , 0)
          / cs.cohort_cnt , 4)                 AS proportion
FROM all_months   am
LEFT JOIN monthly_retention mr  ON am.order_month = mr.order_month
CROSS JOIN cohort_size cs
ORDER BY am.order_month;