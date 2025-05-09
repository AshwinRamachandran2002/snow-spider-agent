SELECT
    TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY-MM') AS "Month",
    u."country" AS "Country",
    p."department" AS "Product_Department",
    p."category" AS "Product_Category",
    COUNT(DISTINCT o."order_id") AS "Number_of_Orders",
    COUNT(DISTINCT o."user_id") AS "Number_of_Unique_Purchasers",
    ROUND(SUM(p."retail_price" - p."cost"), 4) AS "Profit"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi ON o."order_id" = oi."order_id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p ON oi."product_id" = p."id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" u ON o."user_id" = u."id"
WHERE
    TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY') = '2021'
GROUP BY
    "Month",
    "Country",
    "Product_Department",
    "Product_Category"
ORDER BY
    "Month",
    "Country",
    "Product_Department",
    "Product_Category";