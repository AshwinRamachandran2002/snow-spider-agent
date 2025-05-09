WITH purchase_events AS (          -- all completed purchases with a date
    SELECT
        "user_id",
        TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) AS purchase_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS
    WHERE "status" = 'Complete'
      AND "user_id" IS NOT NULL
),

first_purchase AS (               -- first‑ever purchase for every user
    SELECT
        "user_id",
        MIN(purchase_date) AS first_purchase_date
    FROM purchase_events
    GROUP BY "user_id"
),

jan2020_cohort AS (               -- users whose first purchase was in Jan‑2020
    SELECT "user_id"
    FROM first_purchase
    WHERE first_purchase_date BETWEEN '2020-01-01' AND '2020-01-31'
),

months_2020 AS (                  -- the months Feb‑2020 … Dec‑2020
    SELECT DATE_TRUNC('month',
                      DATEADD(month, seq4(), '2020-02-01')) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 11))      -- 11 months
),

returned AS (                     -- cohort users that purchased in each month
    SELECT
        m.month_start,
        COUNT(DISTINCT p."user_id") AS users_returned
    FROM months_2020         m
    LEFT JOIN purchase_events p
           ON p.purchase_date >= m.month_start
          AND p.purchase_date <  DATEADD(month, 1, m.month_start)
          AND p."user_id" IN (SELECT "user_id" FROM jan2020_cohort)
    GROUP BY m.month_start
),

cohort_size AS (                  -- total users in the Jan‑2020 cohort
    SELECT COUNT(DISTINCT "user_id") AS total_users
    FROM jan2020_cohort
)

SELECT
    TO_CHAR(month_start, 'YYYY-MM')                    AS "MONTH",
    users_returned                                     AS "USERS_RETURNED",
    total_users                                        AS "COHORT_USERS",
    ROUND(users_returned / NULLIF(total_users, 0), 4)  AS "PROPORTION_RETURNED"
FROM returned, cohort_size
ORDER BY month_start;