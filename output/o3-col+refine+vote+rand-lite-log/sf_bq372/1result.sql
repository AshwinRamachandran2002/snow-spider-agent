/* -----------------------------------------------------------
   Customer-category whose maximum “lost” order value is
   closest to the overall average of those maxima
------------------------------------------------------------*/
WITH lost_orders AS (          -- Orders that never became invoices
    SELECT so."OrderID",
           cu."CustomerCategoryID"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"  so
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS" cu
           ON so."CustomerID" = cu."CustomerID"
    WHERE  NOT EXISTS ( SELECT 1
                        FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" si
                        WHERE si."OrderID" = so."OrderID" )
),
order_values AS (              -- Total value for every lost order
    SELECT
        lo."CustomerCategoryID",
        lo."OrderID",
        SUM(ol."Quantity" * ol."UnitPrice") AS "OrderValue"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"           ol
    JOIN   lost_orders                                                          lo
           ON ol."OrderID" = lo."OrderID"
    GROUP BY lo."CustomerCategoryID",
             lo."OrderID"
),
cat_max AS (                   -- Maximum lost-order value per category
    SELECT
        "CustomerCategoryID",
        MAX("OrderValue") AS "MaxLostOrderValue"
    FROM   order_values
    GROUP BY "CustomerCategoryID"
),
avg_val AS (                   -- Overall average of those maxima
    SELECT AVG("MaxLostOrderValue") AS "AvgOfCategoryMaxima"
    FROM   cat_max
),
distances AS (                 -- Distance of each category’s max from the average
    SELECT
        cm."CustomerCategoryID",
        cc."CustomerCategoryName",
        cm."MaxLostOrderValue",
        av."AvgOfCategoryMaxima",
        ABS(cm."MaxLostOrderValue" - av."AvgOfCategoryMaxima") AS "DistanceFromAvg"
    FROM   cat_max                            cm
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cc
           ON cc."CustomerCategoryID" = cm."CustomerCategoryID"
    CROSS  JOIN avg_val                       av
)
SELECT
    "CustomerCategoryID",
    "CustomerCategoryName",
    "MaxLostOrderValue",
    "AvgOfCategoryMaxima",
    "DistanceFromAvg"
FROM   distances
ORDER BY "DistanceFromAvg" ASC
LIMIT 1;