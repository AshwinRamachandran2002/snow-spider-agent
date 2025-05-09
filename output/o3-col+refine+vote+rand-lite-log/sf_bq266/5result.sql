SELECT DISTINCT
       TO_CHAR(TO_TIMESTAMP_NTZ(i."sold_at" / 1000000), 'YYYY-MM') AS "month_yyyy_mm",
       p."name"                                                    AS "lowest_profit_product"
FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" i
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p
       ON i."product_id" = p."id"
WHERE  i."sold_at" BETWEEN 1577836800000000       -- 2020-01-01 00:00:00 (µs)
                       AND 1609459199999999       -- 2020-12-31 23:59:59.999999 (µs)
QUALIFY (p."retail_price" - p."cost") = MIN(p."retail_price" - p."cost")
                                    OVER (PARTITION BY TO_CHAR(TO_TIMESTAMP_NTZ(i."sold_at" / 1000000), 'YYYY-MM'))
ORDER BY "month_yyyy_mm";