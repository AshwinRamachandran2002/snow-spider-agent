WITH lost_orders AS (          -- orders that never turned into an invoice
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"   o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
           ON o."OrderID" = i."OrderID"
    WHERE   i."OrderID" IS NULL
),
lost_order_values AS (         -- value of every lost order
    SELECT  l."OrderID",
            c."CustomerCategoryID",
            SUM(ol."UnitPrice" * ol."Quantity")            AS order_value
    FROM    lost_orders                                       l
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
           ON l."OrderID" = ol."OrderID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"   c
           ON l."CustomerID" = c."CustomerID"
    GROUP BY l."OrderID", c."CustomerCategoryID"
),
category_max AS (             -- maximum lost-order value per customer category
    SELECT  "CustomerCategoryID",
            MAX(order_value)  AS max_lost_order_value
    FROM    lost_order_values
    GROUP BY "CustomerCategoryID"
),
avg_overall AS (               -- overall average of those maxima
    SELECT  AVG(max_lost_order_value) AS avg_max_value
    FROM    category_max
),
differences AS (               -- distance of every category’s max to the average
    SELECT  cm."CustomerCategoryID",
            cm.max_lost_order_value,
            ao.avg_max_value,
            ABS(cm.max_lost_order_value - ao.avg_max_value) AS abs_diff
    FROM    category_max  cm
    CROSS JOIN avg_overall ao
)
SELECT  d."CustomerCategoryID",
        cc."CustomerCategoryName",
        d.max_lost_order_value            AS "MaxLostOrderValue",
        d.avg_max_value                   AS "AverageOfMaxima",
        d.abs_diff                        AS "AbsoluteDifference"
FROM    differences                       d
JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cc
       ON d."CustomerCategoryID" = cc."CustomerCategoryID"
ORDER BY d.abs_diff ASC NULLS LAST
LIMIT 1;