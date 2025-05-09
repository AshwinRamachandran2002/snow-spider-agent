WITH order_qty AS (
    -- total purchase quantity per category
    SELECT p."category",
           COUNT(oi."id") AS "total_quantity"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
          ON oi."product_id" = p."id"
    GROUP BY p."category"
),
top_cat AS (
    -- the single top-selling category
    SELECT "category"
    FROM order_qty
    ORDER BY "total_quantity" DESC NULLS LAST
    LIMIT 1
),
top_cat_products AS (
    -- all product-ids that belong to that top category
    SELECT p."id" AS "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
    JOIN top_cat tc
          ON p."category" = tc."category"
),
product_page_events AS (
    -- events that represent a product-detail page view
    SELECT e."session_id",
           e."created_at",
           REGEXP_SUBSTR(e."uri", '/([0-9]+)', 1, 1, 'e')::NUMBER AS "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS e
    WHERE e."uri" ILIKE '%product%'
),
time_diffs AS (
    -- minutes until the next event within the same session
    SELECT ppe."session_id",
           ppe."product_id",
           ( LEAD(ppe."created_at") OVER (PARTITION BY ppe."session_id"
                                          ORDER BY ppe."created_at")
             - ppe."created_at") / 60000000.0 AS "minutes_until_next_event"
    FROM product_page_events ppe
    WHERE ppe."product_id" IN (SELECT "product_id" FROM top_cat_products)
)
SELECT (SELECT "category" FROM top_cat)          AS "top_category",
       ROUND(AVG("minutes_until_next_event"),4)  AS "avg_minutes_spent"
FROM time_diffs
WHERE "minutes_until_next_event" IS NOT NULL;