SELECT
    AVG(total_lifetime_sales) AS "Average_Lifetime_Sales_LTV",
    AVG(percentage_in_First_7_Days) AS "Percentage_in_First_7_Days",
    AVG(percentage_in_First_30_Days) AS "Percentage_in_First_30_Days"
FROM (
    SELECT
        p."customer_id",
        SUM(p."amount") AS total_lifetime_sales,
        SUM(
            CASE WHEN (julianday(p."payment_date") - julianday(fp."first_purchase_date")) <= 7
                 THEN p."amount" ELSE 0 END
        ) * 100.0 / SUM(p."amount") AS percentage_in_First_7_Days,
        SUM(
            CASE WHEN (julianday(p."payment_date") - julianday(fp."first_purchase_date")) <= 30
                 THEN p."amount" ELSE 0 END
        ) * 100.0 / SUM(p."amount") AS percentage_in_First_30_Days
    FROM "payment" p
    JOIN (
        SELECT "customer_id", MIN("payment_date") AS "first_purchase_date"
        FROM "payment"
        GROUP BY "customer_id"
    ) fp ON p."customer_id" = fp."customer_id"
    GROUP BY p."customer_id"
    HAVING SUM(p."amount") > 0
);