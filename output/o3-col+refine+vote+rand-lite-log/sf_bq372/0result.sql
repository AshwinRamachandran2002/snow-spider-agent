WITH lost_orders AS (                 -- value of each order that never became an invoice
    SELECT
        cat."CustomerCategoryName",
        o."OrderID",
        SUM(ol."Quantity" * ol."UnitPrice" * (1 + ol."TaxRate" / 100)) AS "OrderValue"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"            o
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"        ol
           ON o."OrderID" = ol."OrderID"
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"         c
           ON o."CustomerID" = c."CustomerID"
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cat
           ON c."CustomerCategoryID" = cat."CustomerCategoryID"
    LEFT  JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"      i
           ON o."OrderID" = i."OrderID"
    WHERE  i."OrderID" IS NULL                          -- keep only “lost” orders
    GROUP  BY cat."CustomerCategoryName", o."OrderID"
), category_max AS (                 -- maximum lost-order value per customer category
    SELECT
        "CustomerCategoryName",
        MAX("OrderValue") AS "CategoryMaxLost"
    FROM   lost_orders
    GROUP  BY "CustomerCategoryName"
), overall_avg AS (                  -- average of those maxima across all categories
    SELECT AVG("CategoryMaxLost") AS "AvgMax"
    FROM   category_max
)
SELECT
    cm."CustomerCategoryName",
    cm."CategoryMaxLost",
    ABS(cm."CategoryMaxLost" - oa."AvgMax") AS "DistanceFromAvg"
FROM   category_max cm
CROSS  JOIN overall_avg oa
ORDER  BY "DistanceFromAvg" ASC
LIMIT  1;