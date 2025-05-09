/*  Breakdown of product-level engagement metrics
    – views, add-to-cart, purchases and items left in cart
    – catalogue-level pages 1,2,12,13 are excluded
*/
SELECT
    p."page_name"                                                       AS "product_name",
    COALESCE( SUM(CASE WHEN e."event_type" = 1 THEN 1 END), 0 )         AS "view_cnt",
    COALESCE( SUM(CASE WHEN e."event_type" = 2 THEN 1 END), 0 )         AS "add_to_cart_cnt",
    COALESCE( SUM(CASE WHEN e."event_type" = 3 THEN 1 END), 0 )         AS "purchase_cnt",
    COALESCE( SUM(CASE WHEN e."event_type" = 2 THEN 1 END), 0 )
      - COALESCE( SUM(CASE WHEN e."event_type" = 3 THEN 1 END), 0 )     AS "left_in_cart_cnt"
FROM
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_PAGE_HIERARCHY"   p
LEFT JOIN
    "BANK_SALES_TRADING"."BANK_SALES_TRADING"."SHOPPING_CART_EVENTS"          e
      ON  p."page_id" = e."page_id"
      AND p."page_id" NOT IN (1, 2, 12, 13)   -- keep only actual SKU pages during join
WHERE
    p."page_id" NOT IN (1, 2, 12, 13)          -- anchor on all real-product pages
GROUP BY
    p."page_name"
ORDER BY
    p."page_name";