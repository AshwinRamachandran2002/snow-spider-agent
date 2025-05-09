WITH january_cohort AS (
    SELECT "user_id"
    FROM (
        SELECT "user_id", MIN("created_at") AS "first_order_date"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
        GROUP BY "user_id"
    ) first_orders
    WHERE "first_order_date" >= 1577836800000000 AND "first_order_date" < 1580515200000000
),
cohort_size AS (
    SELECT COUNT(DISTINCT "user_id") AS "cohort_size" FROM january_cohort
),
purchases AS (
    SELECT 
        DISTINCT "user_id",
        EXTRACT(MONTH FROM TO_TIMESTAMP("created_at" / 1000000)) AS "MonthNum",
        TO_CHAR(TO_TIMESTAMP("created_at" / 1000000), 'Mon') AS "MonthName"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE
        "user_id" IN (SELECT "user_id" FROM january_cohort)
        AND "created_at" >= 1580515200000000  -- February 1, 2020
        AND "created_at" < 1609459200000000   -- January 1, 2021
)
SELECT
    "MonthName" AS "Month",
    ROUND(COUNT(DISTINCT "user_id")::FLOAT / (SELECT "cohort_size" FROM cohort_size), 4) AS "Proportion"
FROM purchases
GROUP BY "MonthNum", "MonthName"
ORDER BY "MonthNum"