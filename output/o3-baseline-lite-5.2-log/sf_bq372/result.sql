WITH "LOST_ORDERS" AS (      -- orders that never became invoices
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"  i
           ON o."OrderID" = i."OrderID"
    WHERE   i."OrderID" IS NULL
),
"LOST_ORDER_VALUES" AS (     -- total value for every lost order
    SELECT  l."OrderID",
            l."CustomerID",
            SUM(ol."Quantity" * ol."UnitPrice") AS "OrderValue"
    FROM    "LOST_ORDERS"                                                      l
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"       ol
           ON l."OrderID" = ol."OrderID"
    GROUP BY l."OrderID",
             l."CustomerID"
),
"CATEGORY_MAX" AS (          -- maximum lost‑order value per customer category
    SELECT  c."CustomerCategoryID",
            cat."CustomerCategoryName",
            MAX(lov."OrderValue")           AS "MaxLostOrderValue"
    FROM    "LOST_ORDER_VALUES"                                                 lov
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"         c
           ON lov."CustomerID" = c."CustomerID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cat
           ON c."CustomerCategoryID" = cat."CustomerCategoryID"
    GROUP BY c."CustomerCategoryID",
             cat."CustomerCategoryName"
),
"AVG_VAL" AS (               -- overall average of those maxima
    SELECT AVG("MaxLostOrderValue") AS "AvgMaxLostOrderValue"
    FROM   "CATEGORY_MAX"
),
"CLOSEST" AS (               -- difference between each category’s max and the average
    SELECT  cm.*,
            av."AvgMaxLostOrderValue",
            ABS(cm."MaxLostOrderValue" - av."AvgMaxLostOrderValue") AS "Diff"
    FROM    "CATEGORY_MAX" cm
    CROSS JOIN "AVG_VAL"   av
)
SELECT  "CustomerCategoryID",
        "CustomerCategoryName",
        "MaxLostOrderValue",
        "AvgMaxLostOrderValue"
FROM    "CLOSEST"
ORDER BY "Diff" ASC,          -- smallest gap to the average
         "CustomerCategoryID" ASC
LIMIT 1;