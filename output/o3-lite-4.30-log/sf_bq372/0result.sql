WITH lost_orders AS (   -- orders that never became invoices
    SELECT o."OrderID"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES i
           ON o."OrderID" = i."OrderID"
    WHERE i."OrderID" IS NULL
), 
order_values AS (       -- total value of each lost order
    SELECT
        ol."OrderID",
        SUM(ol."Quantity" * ol."UnitPrice") AS "order_value"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES ol
    JOIN lost_orders lo ON lo."OrderID" = ol."OrderID"
    GROUP BY ol."OrderID"
), 
category_max AS (       -- max lost‑order value per customer category
    SELECT
        c."CustomerCategoryID",
        MAX(ov."order_value") AS "max_lost_order_value"
    FROM order_values ov
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS   o
          ON o."OrderID" = ov."OrderID"
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_CUSTOMERS c
          ON c."CustomerID" = o."CustomerID"
    GROUP BY c."CustomerCategoryID"
), 
avg_val AS (            -- overall average of those maxima
    SELECT AVG("max_lost_order_value") AS "avg_max"
    FROM category_max
), 
closest AS (            -- find category whose max is closest to that average
    SELECT
        sc."CustomerCategoryName"                 AS "customer_category",
        cm."max_lost_order_value",
        ABS(cm."max_lost_order_value" - av."avg_max") AS "dist"
    FROM category_max cm
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_CUSTOMERCATEGORIES sc
          ON sc."CustomerCategoryID" = cm."CustomerCategoryID"
    CROSS JOIN avg_val av
)
SELECT
    "customer_category",
    TO_DECIMAL("max_lost_order_value",18,4) AS "maximum_lost_order_value"
FROM closest
ORDER BY "dist" NULLS LAST, "customer_category"
LIMIT 1;