WITH top_category AS (
    SELECT p."category"
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
           ON p."id" = oi."product_id"
    WHERE  oi."status" IN ('Complete','Shipped')
    GROUP  BY p."category"
    ORDER  BY COUNT(oi."id") DESC NULLS LAST, p."category"
    LIMIT  1
),
product_page_events AS (
    SELECT
        p."category",
        ( LEAD(e."created_at") OVER (PARTITION BY e."session_id" ORDER BY e."created_at")
          - e."created_at") / 60000000.0 AS minutes_on_page
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS"   e
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
           ON p."id" = TRY_TO_NUMBER(SPLIT_PART(e."uri", '/', 3))
    WHERE  e."uri" LIKE '/product/%'
      AND  p."category" = (SELECT "category" FROM top_category)
)
SELECT
    (SELECT "category" FROM top_category) AS product_category_name,
    ROUND(AVG(minutes_on_page), 4)        AS average_page_view_time_minutes
FROM product_page_events
WHERE minutes_on_page IS NOT NULL;