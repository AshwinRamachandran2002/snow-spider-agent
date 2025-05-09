SELECT
    TO_CHAR(r."month", 'YYYY-MM') AS "month",
    r."product_name"
FROM (
    /* identify product(s) with the lowest profit in each 2020 month */
    SELECT DISTINCT
        m."month",
        p."name" AS "product_name"
    FROM (
        /* minimum profit per month */
        SELECT
            DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))      AS "month",
            MIN(p."retail_price" - p."cost")                                 AS "min_profit"
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
              ON p."id" = oi."product_id"
        WHERE YEAR(TO_TIMESTAMP(oi."created_at" / 1000000)) = 2020
        GROUP BY DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))
    ) m
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
          ON DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) = m."month"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"       p
          ON p."id" = oi."product_id"
    WHERE (p."retail_price" - p."cost") = m."min_profit"
) r
ORDER BY r."month", r."product_name";