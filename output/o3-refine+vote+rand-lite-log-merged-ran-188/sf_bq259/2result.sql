WITH firsts AS (   -- each shopper’s first-purchase month (cohort)
    SELECT  "user_id",
            DATE_TRUNC(
                'month',
                TO_TIMESTAMP(MIN("created_at")/1000000)
            )                           AS "cohort_month"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE   TO_TIMESTAMP("created_at"/1000000) < '2023-01-01'
    GROUP BY "user_id"
), cohort_orders AS (   -- distinct shopper-month pairs for the first 4 months
    SELECT DISTINCT
           f."user_id",
           MONTHS_BETWEEN(
                DATE_TRUNC('month', TO_TIMESTAMP(o."created_at"/1000000)),
                f."cohort_month"
           )::INT                       AS "month_number"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN   firsts f
      ON   o."user_id" = f."user_id"
    WHERE  TO_TIMESTAMP(o."created_at"/1000000) < '2023-01-01'
      AND  MONTHS_BETWEEN(
                DATE_TRUNC('month', TO_TIMESTAMP(o."created_at"/1000000)),
                f."cohort_month"
           ) BETWEEN 0 AND 3            -- months 0-3 only
), counts AS (      -- user count per relative month across all cohorts
    SELECT  "month_number",
            COUNT(DISTINCT "user_id")   AS "users"
    FROM    cohort_orders
    GROUP BY "month_number"
)
SELECT  100.00                                                AS "pct_month0",    -- base = 100%
        ROUND(100 * COALESCE(MAX(CASE WHEN "month_number"=1 THEN "users" END),0)
                   / MAX(CASE WHEN "month_number"=0 THEN "users" END), 2) AS "pct_month1",
        ROUND(100 * COALESCE(MAX(CASE WHEN "month_number"=2 THEN "users" END),0)
                   / MAX(CASE WHEN "month_number"=0 THEN "users" END), 2) AS "pct_month2",
        ROUND(100 * COALESCE(MAX(CASE WHEN "month_number"=3 THEN "users" END),0)
                   / MAX(CASE WHEN "month_number"=0 THEN "users" END), 2) AS "pct_month3"
FROM    counts;