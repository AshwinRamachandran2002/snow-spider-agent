/*  Cohort-based purchase retention – users whose first order occurred
    on or before 31-Dec-2022.  
    pct_month1 = month of first purchase (offset-0)  
    pct_month2 = first full month after initial purchase (offset-1)  
    pct_month3 = second month after initial purchase (offset-2)  
    pct_month4 = third month after initial purchase (offset-3)          */

WITH first_purchase AS (   -- cohort month for every shopper
    SELECT
        "user_id",
        MIN(DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at" / 1e6)))
            AS "first_purchase_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
),

cohort_activity AS (       -- # of unique purchasers in offsets 0-3
    SELECT
        fp."first_purchase_month"                                            AS "cohort_month",
        MONTHS_BETWEEN(
            DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)),
            fp."first_purchase_month"
        )                                                                    AS "month_offset",
        COUNT(DISTINCT o."user_id")                                          AS "active_users"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN first_purchase fp
      ON fp."user_id" = o."user_id"
    WHERE TO_TIMESTAMP_NTZ(o."created_at" / 1e6) < '2023-01-01'             -- use data ≤ 2022-12-31
      AND MONTHS_BETWEEN(
              DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)),
              fp."first_purchase_month"
          ) BETWEEN 0 AND 3                                                  -- first-through-fourth months
    GROUP BY 1, 2
),

cohort_pivot AS (          -- spread raw counts into columns m0 … m3
    SELECT
        "cohort_month",
        MAX(CASE WHEN "month_offset" = 0 THEN "active_users" END) AS "m0",
        MAX(CASE WHEN "month_offset" = 1 THEN "active_users" END) AS "m1",
        MAX(CASE WHEN "month_offset" = 2 THEN "active_users" END) AS "m2",
        MAX(CASE WHEN "month_offset" = 3 THEN "active_users" END) AS "m3"
    FROM cohort_activity
    GROUP BY "cohort_month"
)

SELECT
    "cohort_month",
    ROUND(100.0 * "m0" / "m0", 2) AS "pct_month1",   -- always 100 %
    ROUND(100.0 * "m1" / "m0", 2) AS "pct_month2",
    ROUND(100.0 * "m2" / "m0", 2) AS "pct_month3",
    ROUND(100.0 * "m3" / "m0", 2) AS "pct_month4"
FROM cohort_pivot
ORDER BY "cohort_month";