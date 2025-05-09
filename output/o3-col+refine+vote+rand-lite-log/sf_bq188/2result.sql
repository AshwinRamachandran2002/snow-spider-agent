WITH top_category AS (      -- 1. find the category with the most purchased items
    SELECT 
        p."category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    GROUP BY p."category"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
page_views AS (             -- 2. dwell-time (minutes) for every product-page view
    SELECT
        TO_NUMBER(
            REGEXP_SUBSTR(e1."uri", '/product/([0-9]+)', 1, 1, 'e', 1)
        )                                               AS "product_id",
        (e2."created_at" - e1."created_at") / 60000000.0 AS "minutes_on_page"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e1
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e2
          ON e1."session_id" = e2."session_id"
         AND e2."created_at"  > e1."created_at"
    WHERE e1."event_type" = 'product'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY e1."id" ORDER BY e2."created_at") = 1
),
page_views_cat AS (         -- 3. map each view to its product category
    SELECT 
        pv."minutes_on_page",
        p."category"
    FROM page_views                                       pv
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"   p
          ON p."id" = pv."product_id"
)
-- 4. average dwell time for the highest-purchased category
SELECT
    (SELECT "category" FROM top_category)  AS "top_category",
    AVG("minutes_on_page")                AS "avg_minutes_on_page"
FROM page_views_cat
WHERE "category" = (SELECT "category" FROM top_category);