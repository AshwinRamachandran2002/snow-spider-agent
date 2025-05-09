WITH lost_orders AS (
    /* 1️⃣  value of every order that never turned into an invoice */
    SELECT  ol."OrderID",
            SUM(ol."Quantity" * ol."UnitPrice")               AS "LostOrderValue"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERLINES ol
    WHERE   ol."OrderID" IN (
            SELECT  so."OrderID"
            FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS   so
            LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_INVOICES si
                   ON so."OrderID" = si."OrderID"
            WHERE   si."OrderID" IS NULL )
    GROUP BY ol."OrderID"
),
per_category AS (
    /* 2️⃣  for every customer category, keep the maximum lost-order value */
    SELECT  cu."CustomerCategoryID",
            MAX(lo."LostOrderValue")                          AS "MaxLostOrderValue"
    FROM        lost_orders                                             lo
    JOIN        WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_ORDERS          so  ON lo."OrderID" = so."OrderID"
    JOIN        WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_CUSTOMERS       cu  ON so."CustomerID" = cu."CustomerID"
    GROUP BY    cu."CustomerCategoryID"
),
avg_val AS (
    /* 3️⃣  overall average of those maxima */
    SELECT  AVG("MaxLostOrderValue")                           AS "AvgMaxLostOrderValue"
    FROM    per_category
)
SELECT  cat."CustomerCategoryName",
        pc."MaxLostOrderValue",
        av."AvgMaxLostOrderValue",
        ABS(pc."MaxLostOrderValue" - av."AvgMaxLostOrderValue") AS "DistanceFromAverage"
FROM        per_category                                                pc
JOIN        WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS.SALES_CUSTOMERCATEGORIES cat
              ON pc."CustomerCategoryID" = cat."CustomerCategoryID"
CROSS JOIN  avg_val                                                     av
ORDER BY    "DistanceFromAverage" ASC
LIMIT 1;