WITH first_purchase_dates AS (
    SELECT "customer_id", MIN("payment_date") AS "first_purchase_date"
    FROM "payment"
    GROUP BY "customer_id"
),
customer_ltv AS (
    SELECT 
        p."customer_id",
        SUM(p."amount") AS "total_lifetime_sales",
        SUM(
            CASE 
                WHEN julianday(p."payment_date") - julianday(f."first_purchase_date") <= 7 THEN p."amount" 
                ELSE 0 
            END
        ) AS "total_amount_7_days",
        SUM(
            CASE 
                WHEN julianday(p."payment_date") - julianday(f."first_purchase_date") <= 30 THEN p."amount" 
                ELSE 0 
            END
        ) AS "total_amount_30_days"
    FROM "payment" p
    JOIN first_purchase_dates f ON p."customer_id" = f."customer_id"
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0
)
SELECT 
    AVG("total_lifetime_sales") AS "Average_Lifetime_Sales_LTV",
    AVG(("total_amount_7_days" / "total_lifetime_sales") * 100) AS "Percentage_in_First_7_Days",
    AVG(("total_amount_30_days" / "total_lifetime_sales") * 100) AS "Percentage_in_First_30_Days"
FROM customer_ltv;