/* 1) find orders that never produced an invoice
   2) calculate the value of each of those lost orders
   3) per customer‑category pick the maximum lost‑order value
   4) compute the average of those maxima
   5) return the category whose maximum is closest to that average            */
WITH lost_orders AS (
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"        o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"    i
           ON o."OrderID" = i."OrderID"
    WHERE   i."OrderID" IS NULL                              -- never invoiced
),
lost_order_values AS (        -- money value for every lost order
    SELECT  lo."OrderID",
            c."CustomerCategoryID",
            SUM(ol."Quantity" * ol."UnitPrice")  AS order_value
    FROM    lost_orders                                                       lo
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"      ol
           ON lo."OrderID" = ol."OrderID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"       c
           ON lo."CustomerID" = c."CustomerID"
    GROUP BY lo."OrderID", c."CustomerCategoryID"
),
category_max AS (              -- step‑3
    SELECT  "CustomerCategoryID",
            MAX(order_value)   AS max_lost_order_value
    FROM    lost_order_values
    GROUP BY "CustomerCategoryID"
),
avg_val AS (                    -- step‑4
    SELECT AVG(max_lost_order_value) AS avg_max_value
    FROM   category_max
),
scored AS (                     -- distance of each maximum from the average
    SELECT  cm."CustomerCategoryID",
            cm.max_lost_order_value,
            ABS(cm.max_lost_order_value - av.avg_max_value) AS diff_from_avg
    FROM    category_max cm
    CROSS JOIN avg_val  av
)
SELECT  cc."CustomerCategoryID",
        cc."CustomerCategoryName",
        s.max_lost_order_value,
        s.diff_from_avg
FROM    scored                               s
JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cc
       ON s."CustomerCategoryID" = cc."CustomerCategoryID"
ORDER BY s.diff_from_avg ASC, cc."CustomerCategoryID"
LIMIT 1;