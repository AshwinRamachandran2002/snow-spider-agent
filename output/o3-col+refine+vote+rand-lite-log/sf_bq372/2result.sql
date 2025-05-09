WITH lost_orders AS (   -- orders that never became invoices
    SELECT 
        o."OrderID",
        o."CustomerID"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"          o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"   i
           ON o."OrderID" = i."OrderID"
    WHERE i."OrderID" IS NULL
),
order_totals AS (       -- value of each “lost” order
    SELECT 
        l."OrderID",
        SUM(l."UnitPrice" * l."Quantity") AS "OrderTotal"
    FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"      l
    JOIN lost_orders lo
      ON l."OrderID" = lo."OrderID"
    GROUP BY l."OrderID"
),
category_max AS (       -- maximum lost-order value per customer category
    SELECT
        cust."CustomerCategoryID",
        MAX(ot."OrderTotal") AS "MaxLostOrderValue"
    FROM order_totals                             ot
    JOIN lost_orders                              lo   ON ot."OrderID" = lo."OrderID"
    JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS" cust  ON lo."CustomerID" = cust."CustomerID"
    GROUP BY cust."CustomerCategoryID"
),
avg_val AS (            -- overall average of those maxima
    SELECT AVG("MaxLostOrderValue") AS "AvgMaxLostOrderValue"
    FROM category_max
)
SELECT
    cm."CustomerCategoryID",
    cat."CustomerCategoryName",
    cm."MaxLostOrderValue",
    av."AvgMaxLostOrderValue",
    ABS(cm."MaxLostOrderValue" - av."AvgMaxLostOrderValue") AS "DistanceFromAverage"
FROM category_max                                                          cm
JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES"  cat
     ON cm."CustomerCategoryID" = cat."CustomerCategoryID"
CROSS JOIN avg_val                                                         av
ORDER BY "DistanceFromAverage" ASC NULLS LAST
LIMIT 1;