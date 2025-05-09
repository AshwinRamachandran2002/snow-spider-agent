SELECT 
    TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'Mon-YYYY') AS "Month",
    p."name" AS "Product_Name",
    SUM(oi."sale_price") - SUM(ii."cost") AS "Profit"
FROM 
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS oi
JOIN 
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" AS ii
    ON oi."inventory_item_id" = ii."id"
JOIN 
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS p
    ON oi."product_id" = p."id"
WHERE 
    oi."status" NOT IN ('Cancelled', 'Returned')
    AND oi."returned_at" IS NULL
    AND oi."created_at" >= 1546300800000000  -- January 1, 2019 in microseconds
    AND oi."created_at" < 1661990400000000   -- September 1, 2022 in microseconds
GROUP BY 
    "Month", p."name"
QUALIFY 
    ROW_NUMBER() OVER (
        PARTITION BY "Month"
        ORDER BY SUM(oi."sale_price") - SUM(ii."cost") DESC
    ) <= 3
ORDER BY 
    "Month" ASC,
    "Profit" DESC NULLS LAST;