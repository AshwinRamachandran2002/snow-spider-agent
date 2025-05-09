WITH category_purchase_counts AS (
    SELECT p."category",
           COUNT(*) AS "total_items"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
      ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
    GROUP BY p."category"
),
top_category AS (
    SELECT "category"
    FROM category_purchase_counts
    ORDER BY "total_items" DESC NULLS LAST
    LIMIT 1
),
product_page_views AS (
    SELECT  e."session_id",
            e."created_at" AS "view_time",
            e."uri",
            LEAD(e."created_at") OVER (PARTITION BY e."session_id"
                                       ORDER BY e."created_at") AS "next_time",
            TRY_TO_NUMBER(SPLIT_PART(e."uri", '/', 3)) AS "product_id"
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS" e
    WHERE   e."event_type" = 'product'
),
views_with_category AS (
    SELECT  ppv."session_id",
            ppv."product_id",
            p."category",
            ("next_time" - "view_time") / 60000000.0 AS "minutes_on_page"
    FROM    product_page_views ppv
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
            ON p."id" = ppv."product_id"
    WHERE   ppv."next_time" IS NOT NULL
      AND   p."category" = (SELECT "category" FROM top_category)
)
SELECT  (SELECT "category" FROM top_category)   AS "category_with_highest_purchases",
        ROUND(AVG("minutes_on_page"), 4)        AS "avg_minutes_spent_per_product_view"
FROM    views_with_category;