WITH first_orders AS (
    -- Get the first valid order date per user
    SELECT
        "user_id",
        MIN("created_at") AS "first_order_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "created_at" <= 1672531199000000  -- Up to 2022-12-31 23:59:59 in microseconds
          AND "status" IN ('Complete', 'Shipped')
    GROUP BY "user_id"
),

user_cohorts AS (
    -- Assign each user to a cohort based on the month of their first purchase (up to August 2022)
    SELECT
        fo."user_id",
        TO_DATE(TO_TIMESTAMP(fo."first_order_at" / 1000000)) AS "first_order_date",
        DATE_TRUNC('month', TO_TIMESTAMP(fo."first_order_at" / 1000000)) AS "cohort_month"
    FROM first_orders fo
    WHERE DATE_TRUNC('month', TO_TIMESTAMP(fo."first_order_at" / 1000000)) <= DATE '2022-08-31'
),

all_orders AS (
    -- Get all valid orders up to the end of 2022
    SELECT
        "user_id",
        TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) AS "order_date"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "created_at" <= 1672531199000000  -- Up to 2022-12-31 23:59:59 in microseconds
          AND "status" IN ('Complete', 'Shipped')
),

orders_after_first AS (
    -- Calculate the number of months after the first purchase for each subsequent order
    SELECT
        ao."user_id",
        DATEDIFF('month', uc."first_order_date", ao."order_date") AS "months_since_first_purchase"
    FROM all_orders ao
    JOIN user_cohorts uc ON ao."user_id" = uc."user_id"
    WHERE ao."order_date" > uc."first_order_date"
          AND DATEDIFF('month', uc."first_order_date", ao."order_date") BETWEEN 1 AND 4
),

purchase_indicators AS (
    -- Determine if the user made a purchase in each of the first four months after their initial purchase
    SELECT
        uc."cohort_month",
        uc."user_id",
        MAX(CASE WHEN oaf."months_since_first_purchase" = 1 THEN 1 ELSE 0 END) AS "purchase_month_1",
        MAX(CASE WHEN oaf."months_since_first_purchase" = 2 THEN 1 ELSE 0 END) AS "purchase_month_2",
        MAX(CASE WHEN oaf."months_since_first_purchase" = 3 THEN 1 ELSE 0 END) AS "purchase_month_3",
        MAX(CASE WHEN oaf."months_since_first_purchase" = 4 THEN 1 ELSE 0 END) AS "purchase_month_4"
        FROM user_cohorts uc
    LEFT JOIN orders_after_first oaf ON uc."user_id" = oaf."user_id"
    GROUP BY uc."cohort_month", uc."user_id"
)

SELECT
    TO_CHAR(pi."cohort_month", 'YYYY-MM') AS "Month_of_First_Purchase",
    ROUND(100 * AVG(pi."purchase_month_1"), 4) AS "Percentage_Repurchase_in_First_Month",
    ROUND(100 * AVG(pi."purchase_month_2"), 4) AS "Percentage_Repurchase_in_Second_Month",
    ROUND(100 * AVG(pi."purchase_month_3"), 4) AS "Percentage_Repurchase_in_Third_Month",
    ROUND(100 * AVG(pi."purchase_month_4"), 4) AS "Percentage_Repurchase_in_Fourth_Month"
FROM purchase_indicators pi
GROUP BY pi."cohort_month"
ORDER BY pi."cohort_month";