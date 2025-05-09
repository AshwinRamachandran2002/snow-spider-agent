WITH lost_orders AS (   -- 1. orders that never became invoices
    SELECT o."OrderID",
           o."CustomerID"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS" o
    WHERE o."OrderID" NOT IN (   -- compare with all invoiced orders
          SELECT DISTINCT i."OrderID"
          FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES" i
          WHERE i."OrderID" IS NOT NULL
    )
),
order_values AS (       -- 2. total value of every lost order
    SELECT lo."OrderID",
           SUM(ol."Quantity" * ol."UnitPrice" * (1 + ol."TaxRate" / 100))       AS "OrderValue"
    FROM lost_orders lo
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" ol
          ON lo."OrderID" = ol."OrderID"
    GROUP BY lo."OrderID"
),
category_max AS (       -- 3. maximum lost‑order value per customer category
    SELECT cat."CustomerCategoryID",
           cat."CustomerCategoryName",
           MAX(ov."OrderValue")                                                   AS "MaxLostOrderValue"
    FROM order_values ov
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS" ord
          ON ov."OrderID" = ord."OrderID"
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS" cus
          ON ord."CustomerID" = cus."CustomerID"
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES" cat
          ON cus."CustomerCategoryID" = cat."CustomerCategoryID"
    GROUP BY cat."CustomerCategoryID", cat."CustomerCategoryName"
)
-- 4. pick the category whose maximum is closest to the overall mean of the maxima
SELECT "CustomerCategoryID",
       "CustomerCategoryName",
       "MaxLostOrderValue"
FROM (
    SELECT cm.*,
           ABS(cm."MaxLostOrderValue" 
               - AVG(cm."MaxLostOrderValue") OVER ())                             AS "Deviation"
    FROM category_max cm
)
ORDER BY "Deviation" ASC, "CustomerCategoryID"
LIMIT 1;