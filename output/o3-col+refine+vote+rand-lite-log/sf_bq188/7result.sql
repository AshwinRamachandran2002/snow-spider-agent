/*  Steps
    1. Find the product category with the greatest total purchase count.
    2. Isolate every product-page view (event_type = 'product' and URI like '/product/{id}').
       Parse the product-id from the URI, join to PRODUCTS, and keep only rows that belong
       to the top-selling category.
    3. Inside every session order the product-page views and grab the very next event time.
    4. Compute the average minutes between the view and the next event.
*/
WITH top_category AS (
    SELECT p."category"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
           ON p."id" = oi."product_id"
    GROUP  BY p."category"
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT  1
),
product_views AS (
    SELECT
        e."session_id",
        e."created_at"                                       AS "view_time",
        TRY_TO_NUMBER( SPLIT_PART(e."uri", '/', 3) )         AS "view_product_id"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS  e
    WHERE  e."event_type" = 'product'
      AND  e."uri" ILIKE '/product/%'
),
filtered_views AS (
    SELECT
        pv."session_id",
        pv."view_time"
    FROM   product_views                                 pv
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
           ON p."id" = pv."view_product_id"
    JOIN   top_category                                  tc
           ON p."category" = tc."category"
),
views_with_next AS (
    SELECT
        "session_id",
        "view_time",
        LEAD("view_time") OVER (PARTITION BY "session_id"
                                ORDER BY "view_time")      AS "next_event_time"
    FROM   filtered_views
)
SELECT
    (SELECT "category" FROM top_category)                    AS "top_category",
    ROUND( AVG( ("next_event_time" - "view_time")/60000000.0 )
         , 4)                                                AS "avg_minutes_on_product_page"
FROM   views_with_next
WHERE  "next_event_time" IS NOT NULL;