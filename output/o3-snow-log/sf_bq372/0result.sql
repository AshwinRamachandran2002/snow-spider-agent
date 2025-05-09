WITH lost_orders AS (          -- orders that were never invoiced
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"         o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"     i
           ON o."OrderID" = i."OrderID"
    WHERE   i."OrderID" IS NULL
),  
lost_order_values AS (         -- value (incl. tax) of every lost order
    SELECT  lo."OrderID",
            SUM(ol."UnitPrice" * ol."Quantity" * (1 + ol."TaxRate" / 100))  AS order_value
    FROM    lost_orders                                                  lo
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
           ON lo."OrderID" = ol."OrderID"
    GROUP BY lo."OrderID"
),  
category_max_values AS (       -- per customer-category: maximum lost order value
    SELECT  c."CustomerCategoryID",
            cat."CustomerCategoryName",
            MAX(lov.order_value)                                       AS max_lost_order_value
    FROM    lost_orders                                                               lo
    JOIN    lost_order_values                                                         lov
           ON lo."OrderID" = lov."OrderID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"               c
           ON lo."CustomerID" = c."CustomerID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES"      cat
           ON c."CustomerCategoryID" = cat."CustomerCategoryID"
    GROUP BY c."CustomerCategoryID",
             cat."CustomerCategoryName"
),  
overall_avg AS (               -- average of the category maxima
    SELECT AVG(max_lost_order_value) AS avg_max_lost_order_value
    FROM   category_max_values
)  
SELECT  cmv."CustomerCategoryID",
        cmv."CustomerCategoryName",
        cmv.max_lost_order_value,
        oa.avg_max_lost_order_value,
        ABS(cmv.max_lost_order_value - oa.avg_max_lost_order_value) AS diff_to_average
FROM    category_max_values  cmv
CROSS JOIN overall_avg       oa
ORDER BY diff_to_average ASC NULLS LAST, cmv."CustomerCategoryID"
LIMIT 1;