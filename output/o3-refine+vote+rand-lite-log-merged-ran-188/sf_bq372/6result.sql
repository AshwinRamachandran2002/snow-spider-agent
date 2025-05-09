WITH
/* 1.  Orders that were never invoiced (“lost” orders) with their total value */
lost_orders_value AS (
    SELECT
        o."OrderID",
        c."CustomerCategoryID",
        SUM(l."Quantity" * l."UnitPrice" * (1 + l."TaxRate" / 100)) AS "OrderValue"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"            o
    LEFT JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     i
           ON o."OrderID" = i."OrderID"
    JOIN      "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"   l
           ON o."OrderID" = l."OrderID"
    JOIN      "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS"    c
           ON o."CustomerID" = c."CustomerID"
    WHERE i."OrderID" IS NULL                         -- keep only orders absent from invoices
    GROUP BY o."OrderID", c."CustomerCategoryID"
),

/* 2.  Per‑category maximum lost order value */
category_max AS (
    SELECT
        "CustomerCategoryID",
        MAX("OrderValue") AS "MaxLostOrderValue"
    FROM lost_orders_value
    GROUP BY "CustomerCategoryID"
),

/* 3.  Overall average of those per‑category maxima */
overall_avg AS (
    SELECT AVG("MaxLostOrderValue") AS "AvgMaxLostOrderValue"
    FROM category_max
)

/* 4.  Category whose maximum is closest to the overall average */
SELECT
    cm."CustomerCategoryID",
    cat."CustomerCategoryName",
    cm."MaxLostOrderValue",
    oa."AvgMaxLostOrderValue",
    ABS(cm."MaxLostOrderValue" - oa."AvgMaxLostOrderValue") AS "DifferenceToAvg"
FROM category_max                                              cm
JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES" cat
     ON cm."CustomerCategoryID" = cat."CustomerCategoryID"
CROSS JOIN overall_avg                                          oa
ORDER BY "DifferenceToAvg" ASC, cm."CustomerCategoryID" ASC
LIMIT 1;