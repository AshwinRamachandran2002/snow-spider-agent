/*  Customer category whose **maximum lost‑order value** is closest 
    to the overall average of these maxima                                    */

WITH
/* 1. Orders that never became invoices */
"LOST_ORDERS" AS (
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"  o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
           ON o."OrderID" = i."OrderID"
    WHERE   i."OrderID" IS NULL
),

/* 2. Monetary value of every lost order (Σ Quantity*UnitPrice) */
"ORDER_VALUES" AS (
    SELECT  lo."OrderID",
            SUM(ol."Quantity" * ol."UnitPrice") AS "OrderTotal"
    FROM    "LOST_ORDERS"                                  lo
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"  ol
           ON lo."OrderID" = ol."OrderID"
    GROUP BY lo."OrderID"
),

/* 3. Maximum lost‑order value per customer category */
"CATEGORY_MAX" AS (
    SELECT  cc."CustomerCategoryID",
            cc."CustomerCategoryName",
            MAX(ov."OrderTotal")           AS "MaxLostOrderValue"
    FROM            "ORDER_VALUES"                                ov
    JOIN            "LOST_ORDERS"                                 lo  ON ov."OrderID"    = lo."OrderID"
    JOIN            WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"          c   ON lo."CustomerID" = c."CustomerID"
    JOIN            WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cc  ON c."CustomerCategoryID" = cc."CustomerCategoryID"
    GROUP BY        cc."CustomerCategoryID",
                    cc."CustomerCategoryName"
),

/* 4. Average of those maxima */
"AVG_MAX" AS (
    SELECT  AVG("MaxLostOrderValue") AS "AvgMaxValue"
    FROM    "CATEGORY_MAX"
),

/* 5. Pick the category whose maximum is closest to that average */
"RANKED" AS (
    SELECT  cm.*,
            av."AvgMaxValue",
            ABS(cm."MaxLostOrderValue" - av."AvgMaxValue") AS "Diff",
            ROW_NUMBER() OVER (ORDER BY ABS(cm."MaxLostOrderValue" - av."AvgMaxValue")) AS "RN"
    FROM    "CATEGORY_MAX" cm
    CROSS JOIN "AVG_MAX"  av
)

SELECT  "CustomerCategoryID",
        "CustomerCategoryName",
        "MaxLostOrderValue",
        "AvgMaxValue"
FROM    "RANKED"
WHERE   "RN" = 1;