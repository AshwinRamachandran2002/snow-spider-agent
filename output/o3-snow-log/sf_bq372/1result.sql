WITH lost_orders AS (           -- orders that never produced an invoice
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"  i
           ON i."OrderID" = o."OrderID"
    WHERE   i."OrderID" IS NULL
),
order_values AS (               -- value of each lost order
    SELECT  lo."OrderID",
            lo."CustomerID",
            SUM(ol."Quantity" * ol."UnitPrice")  AS order_value
    FROM    lost_orders                                                lo
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
           ON ol."OrderID" = lo."OrderID"
    GROUP BY lo."OrderID", lo."CustomerID"
),
category_max AS (               -- maximum lost-order value per customer category
    SELECT  c."CustomerCategoryID",
            cat."CustomerCategoryName",
            MAX(ov.order_value)              AS max_lost_order_value
    FROM    order_values                                                       ov
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"        c
           ON c."CustomerID" = ov."CustomerID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cat
           ON cat."CustomerCategoryID" = c."CustomerCategoryID"
    GROUP BY c."CustomerCategoryID", cat."CustomerCategoryName"
),
average_cte AS (                -- overall average of those maxima
    SELECT AVG(max_lost_order_value) AS avg_max_value
    FROM   category_max
),
closest AS (                    -- distance of each category’s max to the average
    SELECT  cm.*,
            a.avg_max_value,
            ABS(cm.max_lost_order_value - a.avg_max_value) AS diff_to_avg
    FROM    category_max cm
    CROSS JOIN average_cte a
)
SELECT  "CustomerCategoryID",
        "CustomerCategoryName",
        max_lost_order_value      AS "MaxLostOrderValue",
        avg_max_value             AS "AverageOfCategoryMaxima",
        diff_to_avg               AS "DistanceToAverage"
FROM    closest
ORDER BY diff_to_avg ASC, "CustomerCategoryID" ASC   -- tie-breaker
LIMIT 1;