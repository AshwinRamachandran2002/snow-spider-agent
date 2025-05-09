WITH lost_orders AS (   -- orders that never became invoices
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"        o
    LEFT JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"    i
           ON o."OrderID" = i."OrderID"
    WHERE   i."OrderID" IS NULL
),
order_values AS (       -- value of each lost order
    SELECT  l."OrderID",
            l."CustomerID",
            SUM(ol."Quantity" * ol."UnitPrice")          AS "OrderValue"
    FROM    lost_orders                                                     l
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" ol
           ON l."OrderID" = ol."OrderID"
    GROUP BY l."OrderID", l."CustomerID"
),
category_max AS (       -- maximum lost‑order value per customer category
    SELECT  c."CustomerCategoryID",
            cat."CustomerCategoryName",
            MAX(ov."OrderValue")                       AS "MaxLostOrderValue"
    FROM    order_values                                                    ov
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS"  c
           ON ov."CustomerID" = c."CustomerID"
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES" cat
           ON c."CustomerCategoryID" = cat."CustomerCategoryID"
    GROUP BY c."CustomerCategoryID", cat."CustomerCategoryName"
),
stats AS (              -- add overall average of the maxima
    SELECT  *,
            AVG("MaxLostOrderValue") OVER ()            AS "AvgMaxLostOrderValue"
    FROM    category_max
),
ranked AS (             -- distance of each category’s max to the average
    SELECT  *,
            ABS("MaxLostOrderValue" - "AvgMaxLostOrderValue") AS "Diff",
            ROW_NUMBER() OVER (ORDER BY ABS("MaxLostOrderValue" - "AvgMaxLostOrderValue"),
                                         "CustomerCategoryID")              AS rn
    FROM    stats
)
SELECT  "CustomerCategoryID",
        "CustomerCategoryName",
        "MaxLostOrderValue",
        "AvgMaxLostOrderValue",
        "Diff"
FROM    ranked
WHERE   rn = 1;