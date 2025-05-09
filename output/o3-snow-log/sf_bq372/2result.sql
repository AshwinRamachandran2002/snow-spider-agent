WITH lost_orders AS
(
    /* Orders that never turned into invoices
       together with their total (tax-inclusive) value            */
    SELECT  o."OrderID",
            c."CustomerCategoryID",
            SUM( ol."Quantity"
                 * ol."UnitPrice"
                 * (1 + COALESCE(ol."TaxRate",0) / 100) )        AS order_value
    FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"      o
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES"  ol
           ON ol."OrderID" = o."OrderID"
    JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS"   c
           ON c."CustomerID" = o."CustomerID"
    LEFT JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"  i
           ON i."OrderID" = o."OrderID"
    WHERE   i."OrderID" IS NULL
    GROUP BY o."OrderID", c."CustomerCategoryID"
),
max_per_category AS
(
    SELECT  "CustomerCategoryID",
            MAX(order_value)                             AS max_lost_order_value
    FROM    lost_orders
    GROUP BY "CustomerCategoryID"
),
overall_avg AS
(
    SELECT  AVG(max_lost_order_value)                    AS avg_of_maxima
    FROM    max_per_category
)
SELECT  cat."CustomerCategoryID",
        cat."CustomerCategoryName",
        mpc.max_lost_order_value,
        ova.avg_of_maxima,
        ABS(mpc.max_lost_order_value - ova.avg_of_maxima) AS diff_from_avg
FROM    max_per_category                                                   mpc
CROSS JOIN overall_avg                                                     ova
JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES"  cat
       ON cat."CustomerCategoryID" = mpc."CustomerCategoryID"
QUALIFY diff_from_avg = MIN(diff_from_avg) OVER()
;