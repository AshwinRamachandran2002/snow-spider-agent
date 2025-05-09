WITH lost_orders AS (
    /* Orders that never became invoices */
    SELECT  o."OrderID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS        o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES    i
           ON o."OrderID" = i."OrderID"
    WHERE   i."OrderID" IS NULL
),
order_values AS (
    /* Calculate total value of each lost order               */
    /* (quantity * unit price, excluding tax and discounts)   */
    SELECT  ol."OrderID",
            SUM(ol."Quantity" * ol."UnitPrice") AS order_value
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES ol
    JOIN    lost_orders lo
           ON lo."OrderID" = ol."OrderID"
    GROUP BY ol."OrderID"
),
category_max AS (
    /* For every customer category, find the maximum lost order value */
    SELECT  cc."CustomerCategoryID",
            cc."CustomerCategoryName",
            MAX(ov.order_value) AS max_lost_order_value
    FROM    order_values                                           ov
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS o
           ON o."OrderID" = ov."OrderID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_CUSTOMERS c
           ON c."CustomerID" = o."CustomerID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_CUSTOMERCATEGORIES cc
           ON cc."CustomerCategoryID" = c."CustomerCategoryID"
    GROUP BY cc."CustomerCategoryID", cc."CustomerCategoryName"
),
avg_max AS (
    /* Overall average of the category-level maxima */
    SELECT AVG(max_lost_order_value) AS avg_max_value
    FROM   category_max
)
SELECT  cm."CustomerCategoryID",
        cm."CustomerCategoryName",
        cm.max_lost_order_value,
        am.avg_max_value,
        ABS(cm.max_lost_order_value - am.avg_max_value) AS diff_from_avg
FROM    category_max cm
CROSS JOIN avg_max  am
ORDER BY diff_from_avg ASC, cm."CustomerCategoryID"
LIMIT 1;