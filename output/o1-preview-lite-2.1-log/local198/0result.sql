SELECT ROUND(AVG("TotalSales"), 4) AS "Median_Total_Sales" FROM (
    SELECT "TotalSales" FROM (
        SELECT SUM("invoices"."Total") AS "TotalSales"
        FROM "invoices"
        JOIN "customers" ON "invoices"."CustomerId" = "customers"."CustomerId"
        WHERE "customers"."Country" IN (
            SELECT "Country"
            FROM "customers"
            GROUP BY "Country"
            HAVING COUNT(*) > 4
        )
        GROUP BY "customers"."Country"
    ) ORDER BY "TotalSales" ASC
    LIMIT 2 OFFSET 1
);