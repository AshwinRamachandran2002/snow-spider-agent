WITH category_totals AS (   -- total purchase quantity per product category
    SELECT  p."category",
            COUNT(*) AS "total_order_items"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p   ON oi."product_id" = p."id"
    GROUP BY p."category"
), top_category AS (        -- category with the highest purchase quantity
    SELECT  "category"
    FROM    category_totals
    ORDER BY "total_order_items" DESC NULLS LAST
    LIMIT 1
), event_times AS (         -- minutes between a product-page view and the next event in the same session
    SELECT
        TRY_TO_NUMBER( SPLIT_PART(e."uri", '/product/', 2) )                          AS "product_id",
        ( LEAD(e."created_at") OVER (PARTITION BY e."session_id" 
                                     ORDER BY e."created_at")
          - e."created_at") / 60000000.0                                             AS "minutes_on_page"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE  e."uri" ILIKE '%/product/%'
), avg_time_top_category AS (  -- average minutes on page for the top category
    SELECT
        p."category",
        ROUND( AVG(et."minutes_on_page"), 4 )  AS "avg_minutes_on_page"
    FROM    event_times                     et
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
            ON et."product_id" = p."id"
    JOIN    top_category tc
            ON p."category" = tc."category"
    WHERE   et."minutes_on_page" IS NOT NULL
    GROUP BY p."category"
)
SELECT  "category",
        "avg_minutes_on_page"
FROM    avg_time_top_category;