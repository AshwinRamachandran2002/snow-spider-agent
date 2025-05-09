WITH first_purchase AS (
    SELECT
        "customer_id",
        MIN("payment_date") AS "initial_purchase_date"
    FROM "payment"
    GROUP BY "customer_id"
),
customer_totals AS (
    SELECT
        p."customer_id",
        SUM(p."amount") AS "total_lifetime_sales"
    FROM "payment" AS p
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0
),
customer_sales AS (
    SELECT
        ct."customer_id",
        ct."total_lifetime_sales",
        SUM(CASE WHEN p."payment_date" >= fp."initial_purchase_date"
                 AND p."payment_date" < datetime(fp."initial_purchase_date", '+7 days')
                 THEN p."amount" ELSE 0 END) AS "sales_first_7_days",
        SUM(CASE WHEN p."payment_date" >= fp."initial_purchase_date"
                 AND p."payment_date" < datetime(fp."initial_purchase_date", '+30 days')
                 THEN p."amount" ELSE 0 END) AS "sales_first_30_days"
        FROM "payment" AS p
        JOIN customer_totals ct ON p."customer_id" = ct."customer_id"
        JOIN first_purchase fp ON p."customer_id" = fp."customer_id"
        GROUP BY p."customer_id"
),
customer_percentages AS (
    SELECT
        cs."customer_id",
        cs."total_lifetime_sales",
        cs."sales_first_7_days",
        cs."sales_first_30_days",
        (cs."sales_first_7_days" / cs."total_lifetime_sales") * 100 AS "Percentage_First_7_Days",
        (cs."sales_first_30_days" / cs."total_lifetime_sales") * 100 AS "Percentage_First_30_Days"
    FROM customer_sales cs
)
SELECT
    ROUND(AVG("total_lifetime_sales"), 4) AS "Average_LTV",
    ROUND(AVG("Percentage_First_7_Days"), 4) || '%' AS "Percentage_First_7_Days",
    ROUND(AVG("Percentage_First_30_Days"), 4) || '%' AS "Percentage_First_30_Days"
FROM customer_percentages;