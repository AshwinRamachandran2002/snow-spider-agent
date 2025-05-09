WITH lost_orders AS (   -- orders that never became invoices
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"  o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
           ON i."OrderID" = o."OrderID"
    WHERE   i."OrderID" IS NULL
), 
order_values AS (       -- value of every lost order
    SELECT  lo."OrderID",
            SUM(ol."Quantity" * ol."UnitPrice") AS order_value
    FROM    lost_orders                                    lo
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol 
           ON ol."OrderID" = lo."OrderID"
    GROUP BY lo."OrderID"
), 
lost_orders_with_cat AS (   -- attach customer-category
    SELECT  ov."OrderID",
            sc."CustomerCategoryID",
            ov.order_value
    FROM    order_values                                   ov
    JOIN    lost_orders                                    lo  ON lo."OrderID" = ov."OrderID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"      sc ON sc."CustomerID" = lo."CustomerID"
), 
max_per_category AS (      -- maximum lost order value per category
    SELECT  "CustomerCategoryID",
            MAX(order_value)      AS max_lost_order_value
    FROM    lost_orders_with_cat
    GROUP BY "CustomerCategoryID"
), 
overall_avg AS (           -- average of those maxima
    SELECT AVG(max_lost_order_value) AS avg_max_lost_order_value
    FROM   max_per_category
), 
ranked AS (                -- distance from the average
    SELECT  m."CustomerCategoryID",
            cc."CustomerCategoryName",
            m.max_lost_order_value,
            a.avg_max_lost_order_value,
            ABS(m.max_lost_order_value - a.avg_max_lost_order_value) AS diff_from_avg
    FROM    max_per_category                                      m
    CROSS JOIN overall_avg                                        a
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cc
           ON cc."CustomerCategoryID" = m."CustomerCategoryID"
)
SELECT  "CustomerCategoryID",
        "CustomerCategoryName",
        max_lost_order_value,
        avg_max_lost_order_value,
        diff_from_avg
FROM    ranked
ORDER BY diff_from_avg ASC, "CustomerCategoryID" ASC      -- tie-breaker
LIMIT 1;