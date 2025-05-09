WITH orders_without_invoice AS (          -- orders that never became invoices
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"   i
           ON i."OrderID" = o."OrderID"
    WHERE   i."OrderID" IS NULL
),
order_values AS (                         -- total value of each lost order
    SELECT  l."OrderID",
            SUM(l."Quantity" * l."UnitPrice")          AS "OrderValue"
    FROM    orders_without_invoice                    owi
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   l
           ON l."OrderID" = owi."OrderID"
    GROUP BY l."OrderID"
),
category_max AS (                         -- max lost‑order value per customer category
    SELECT  c."CustomerCategoryID",
            MAX(ov."OrderValue")          AS "MaxLostOrderValue"
    FROM    orders_without_invoice                    owi
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"    c
           ON c."CustomerID" = owi."CustomerID"
    JOIN    order_values                                ov
           ON ov."OrderID" = owi."OrderID"
    GROUP BY c."CustomerCategoryID"
),
category_stats AS (                       -- add overall average of those maxima
    SELECT  cm."CustomerCategoryID",
            cm."MaxLostOrderValue",
            AVG(cm."MaxLostOrderValue")   OVER ()      AS "AvgOfCategoryMaxes"
    FROM    category_max cm
),
ranked AS (                               -- distance of each category from the average
    SELECT  cs.*,
            ABS(cs."MaxLostOrderValue" - cs."AvgOfCategoryMaxes") AS "DifferenceFromAvg",
            ROW_NUMBER() OVER (ORDER BY ABS(cs."MaxLostOrderValue" - cs."AvgOfCategoryMaxes")) AS rn
    FROM    category_stats cs
)
SELECT  r."CustomerCategoryID",
        cc."CustomerCategoryName",
        r."MaxLostOrderValue",
        r."AvgOfCategoryMaxes",
        r."DifferenceFromAvg"
FROM    ranked                                           r
JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cc
       ON cc."CustomerCategoryID" = r."CustomerCategoryID"
WHERE   r.rn = 1;        -- customer category whose max lost‑order value is closest to the average