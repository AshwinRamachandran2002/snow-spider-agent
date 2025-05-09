WITH orders AS (
    SELECT
        "user_id",
        "status",
        TO_TIMESTAMP("created_at" / 1000000)                     AS order_ts,
        DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000)) AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "user_id" IS NOT NULL
      AND "created_at" IS NOT NULL
      AND "status" <> 'Cancelled'          -- keep only effective purchases
),
first_purchase AS (                       -- first purchase month for every user
    SELECT
        "user_id",
        MIN(order_month) AS first_month
    FROM orders
    GROUP BY "user_id"
),
cohort_users AS (                         -- users whose first purchase was in Jan‑2020
    SELECT "user_id"
    FROM first_purchase
    WHERE first_month = '2020-01-01'
),
cohort_size AS (                          -- size of the Jan‑2020 cohort
    SELECT COUNT(*) AS total_users
    FROM cohort_users
),
returns_2020 AS (                         -- distinct cohort users who bought again in 2020
    SELECT
        DATE_TRUNC('month', o.order_ts) AS month,
        COUNT(DISTINCT o."user_id")      AS returning_users
    FROM orders o
    JOIN cohort_users cu
      ON cu."user_id" = o."user_id"
    WHERE o.order_ts >= '2020-02-01'      -- months after the cohort month
      AND o.order_ts <  '2021-01-01'      -- limit to year‑2020
    GROUP BY 1
),
months_2020 AS (                          -- generate Feb‑2020 … Dec‑2020
    SELECT DATE_TRUNC('month',
                      DATEADD(month, seq4(), '2020-02-01')) AS month
    FROM TABLE(GENERATOR(ROWCOUNT => 11))
)
SELECT
    m.month,
    COALESCE(r.returning_users, 0)                       AS returning_users,
    c.total_users                                        AS cohort_users,
    ROUND(COALESCE(r.returning_users, 0)::FLOAT
          / c.total_users, 4)                            AS proportion_returned
FROM months_2020         m
LEFT JOIN returns_2020   r ON r.month = m.month
CROSS JOIN cohort_size   c
ORDER BY m.month;