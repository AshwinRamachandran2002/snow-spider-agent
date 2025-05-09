WITH lost_order_values AS (   -- every order that never became an invoice + its value
    SELECT 
        o."OrderID",
        cust."CustomerCategoryID",
        SUM(ol."Quantity" * ol."UnitPrice")                                    AS order_value
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"          o
    LEFT JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"   i
           ON i."OrderID" = o."OrderID"                                        -- keep ONLY non‑invoiced
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"      ol
           ON ol."OrderID" = o."OrderID"
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS"       cust
           ON cust."CustomerID" = o."CustomerID"
    WHERE i."OrderID" IS NULL
    GROUP BY o."OrderID", cust."CustomerCategoryID"
),                                                                              -- maximum lost value per category
category_max AS (                                                               
    SELECT 
        lov."CustomerCategoryID",
        cat."CustomerCategoryName",
        MAX(lov.order_value)                      AS max_lost_order_value
    FROM lost_order_values                                  lov
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES" cat
         ON cat."CustomerCategoryID" = lov."CustomerCategoryID"
    GROUP BY lov."CustomerCategoryID", cat."CustomerCategoryName"
),                                                                              -- overall average of those maxima
overall_avg AS (
    SELECT AVG(max_lost_order_value) AS avg_max_value
    FROM category_max
)
SELECT 
    cm."CustomerCategoryName",
    cm."CustomerCategoryID",
    cm.max_lost_order_value
FROM category_max  cm
CROSS JOIN overall_avg oa
ORDER BY ABS(cm.max_lost_order_value - oa.avg_max_value) ASC,   -- closest to overall average
         cm."CustomerCategoryID"
LIMIT 1;