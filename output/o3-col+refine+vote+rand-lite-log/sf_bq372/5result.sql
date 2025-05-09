WITH lost_order_values AS (   -- total value for every order that never became an invoice
    SELECT 
        o."OrderID",
        o."CustomerID",
        SUM(ol."Quantity" * ol."UnitPrice") AS "LostOrderValue"
    FROM  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       o
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   ol
          ON ol."OrderID" = o."OrderID"
    WHERE NOT EXISTS (                       -- exclude orders that have an invoice
              SELECT 1
              FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
              WHERE i."OrderID" = o."OrderID"
          )
    GROUP BY o."OrderID", o."CustomerID"
), cat_max AS (             -- maximum lost-order value per customer category
    SELECT 
        c."CustomerCategoryID",
        MAX(lov."LostOrderValue") AS "MaxLostOrderValue"
    FROM  lost_order_values                            lov
    JOIN  WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"        c
          ON c."CustomerID" = lov."CustomerID"
    GROUP BY c."CustomerCategoryID"
), avg_val AS (             -- overall average of those maxima
    SELECT AVG("MaxLostOrderValue") AS "AvgMax" FROM cat_max
)
SELECT 
    cm."CustomerCategoryID",
    cc."CustomerCategoryName",
    cm."MaxLostOrderValue",
    ABS(cm."MaxLostOrderValue" - av."AvgMax") AS "DifferenceToAvg"
FROM        cat_max                                            cm
CROSS JOIN  avg_val                                            av
JOIN        WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cc
      ON    cc."CustomerCategoryID" = cm."CustomerCategoryID"
ORDER BY "DifferenceToAvg" ASC
LIMIT 1;