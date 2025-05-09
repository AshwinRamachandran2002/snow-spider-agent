WITH lost_orders AS (          -- orders that never turned into an invoice
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"   i
           ON i."OrderID" = o."OrderID"
    WHERE   i."OrderID" IS NULL
), 

order_values AS (              -- value of every order (sum of line values)
    SELECT  ol."OrderID",
            SUM(ol."UnitPrice" * ol."Quantity") AS order_value
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
    GROUP BY ol."OrderID"
), 

lost_orders_values AS (        -- lost orders with their values
    SELECT  lo."CustomerID",
            ov.order_value
    FROM    lost_orders   lo
    JOIN    order_values  ov ON ov."OrderID" = lo."OrderID"
), 

category_max_values AS (       -- for each customer category: max lost-order value
    SELECT  cat."CustomerCategoryID",
            MAX(lov.order_value) AS max_lost_value
    FROM    lost_orders_values                                        lov
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"           c
           ON c."CustomerID" = lov."CustomerID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES"  cat
           ON cat."CustomerCategoryID" = c."CustomerCategoryID"
    GROUP BY cat."CustomerCategoryID"
), 

average_value AS (             -- overall average of those maxima
    SELECT AVG(max_lost_value) AS avg_max_value
    FROM   category_max_values
), 

closest_category AS (          -- category whose max is closest to the average
    SELECT  cmv."CustomerCategoryID",
            cmv.max_lost_value,
            ABS(cmv.max_lost_value - av.avg_max_value) AS diff
    FROM    category_max_values  cmv
    CROSS JOIN average_value     av
    QUALIFY diff = MIN(diff) OVER ()        -- keep the closest one (ties kept)
)

SELECT  cc."CustomerCategoryID",
        sc."CustomerCategoryName",
        cc.max_lost_value
FROM    closest_category                                        cc
JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" sc
       ON sc."CustomerCategoryID" = cc."CustomerCategoryID";