WITH firsts AS (                      -- first purchase date for every user
    SELECT "user_id",
           MIN("created_at") AS "first_created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    GROUP BY "user_id"
),
jan_cohort AS (                       -- users whose very first order was in Jan‑2020
    SELECT "user_id"
    FROM firsts
    WHERE TO_TIMESTAMP("first_created_at" / 1000000)
          BETWEEN '2020-01-01' AND '2020-01-31'
),
cohort_size AS (                      -- total size of that cohort
    SELECT COUNT(*) AS total_users FROM jan_cohort
),
months AS (                           -- list of all months Feb‑2020 .. Dec‑2020
    SELECT DATEADD(
               month,
               ROW_NUMBER() OVER (ORDER BY seq4()) - 1,
               TO_DATE('2020-02-01')
           ) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 11))
),
monthly_returns AS (                  -- how many cohort users ordered in each month
    SELECT DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000)) AS month_start,
           COUNT(DISTINCT o."user_id")                              AS users_returned
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN jan_cohort USING ("user_id")
    WHERE TO_TIMESTAMP(o."created_at" / 1000000)
          BETWEEN '2020-02-01' AND '2020-12-31'
    GROUP BY month_start
)
SELECT 
    TO_CHAR(m.month_start, 'YYYY-MM')                                             AS month,
    ROUND(COALESCE(r.users_returned, 0) 
          / NULLIF(c.total_users, 0), 4)                                          AS proportion_returned
FROM months m
CROSS JOIN cohort_size c
LEFT JOIN monthly_returns r ON m.month_start = r.month_start
ORDER BY month;