/* 1.  Find all orders that have NO matching record in the invoice table           */
/* 2.  Work out the (gross) value of those “lost” orders from their order-lines    */
/* 3.  For every customer category take the MAXIMUM of those lost order values     */
/* 4.  Work out the average of all those maxima                                    */
/* 5.  Return the customer-category whose maximum lost order value is              */
/*     closest to that average                                                     */
WITH
/* Orders that never turned into an invoice */
lost_orders AS (
    SELECT  o."OrderID",
            o."CustomerID"
    FROM    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
    LEFT JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES"  i
           ON o."OrderID" = i."OrderID"
    WHERE   i."OrderID" IS NULL
),
/* Calculate the value of each lost order from its order-lines                     */
/* (UnitPrice * Quantity * (1 + TaxRate/100) )                                     */
order_values AS (
    SELECT  l."OrderID",
            SUM(ol."UnitPrice" * ol."Quantity" * (1 + ol."TaxRate" / 100))    AS "OrderValue"
    FROM    lost_orders                                                        l
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"       ol
           ON l."OrderID" = ol."OrderID"
    GROUP BY l."OrderID"
),
/* Attach customer category to every lost order value                              */
orders_with_category AS (
    SELECT  ov."OrderValue",
            c."CustomerCategoryID"
    FROM    order_values                                                        ov
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"            o
           ON ov."OrderID" = o."OrderID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"         c
           ON o."CustomerID" = c."CustomerID"
),
/* For every category: its maximum lost order value                                */
max_per_category AS (
    SELECT  "CustomerCategoryID",
            MAX("OrderValue")  AS "MaxLostOrderValue"
    FROM    orders_with_category
    GROUP BY "CustomerCategoryID"
),
/* Overall average of those maxima                                                 */
avg_value AS (
    SELECT  AVG("MaxLostOrderValue") AS "AvgMaxLostOrderValue"
    FROM    max_per_category
),
/* Distance of each category’s maximum from the overall average                   */
distances AS (
    SELECT  m."CustomerCategoryID",
            m."MaxLostOrderValue",
            ABS(m."MaxLostOrderValue" - a."AvgMaxLostOrderValue") AS "DiffToAvg"
    FROM    max_per_category  m
    CROSS JOIN avg_value      a
)
/* Pick the category whose maximum is closest to the average                       */
SELECT      d."CustomerCategoryID",
            cat."CustomerCategoryName",
            d."MaxLostOrderValue"
FROM        distances                                             d
JOIN        WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cat
           ON d."CustomerCategoryID" = cat."CustomerCategoryID"
QUALIFY     d."DiffToAvg" = MIN(d."DiffToAvg") OVER ()
;