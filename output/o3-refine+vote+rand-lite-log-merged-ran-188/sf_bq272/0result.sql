/*  Top-3 most profitable products for every month
    from 2019-01 through 2022-08 (exclusive of cancelled/returned)  */
SELECT
    "year_month",
    "product_name",
    ROUND("profit", 4) AS "profit",
    "rk"
FROM (
        SELECT
            TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM')                       AS "year_month",
            p."name"                                                                              AS "product_name",
            SUM(oi."sale_price") - SUM(ii."cost")                                                AS "profit",
            ROW_NUMBER() OVER (
                               PARTITION BY TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM')
                               ORDER BY  SUM(oi."sale_price") - SUM(ii."cost") DESC NULLS LAST
                              )                                                                  AS "rk"
        FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi
        JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
               ON oi."inventory_item_id" = ii."id"
        JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p
               ON oi."product_id" = p."id"
        WHERE  oi."status" NOT IN ('Cancelled', 'Returned')
          AND  oi."created_at" BETWEEN 1546300800000000        /* 2019-01-01 00:00:00 */
                                   AND 1661999999000000        /* 2022-08-31 23:59:59 */
        GROUP  BY
               TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM'),
               p."name"
     )
WHERE  "rk" <= 3
ORDER  BY
        "year_month",
        "rk";