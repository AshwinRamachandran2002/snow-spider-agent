WITH top_category AS (
    /* 1. Find the category with the highest total purchase quantity */
    SELECT p."category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
          ON oi."product_id" = p."id"
    GROUP BY p."category"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
events_with_product AS (
    /* 2. Capture every product‑page view and parse its product_id from the URI */
    SELECT
        e."session_id",
        e."created_at",
        LEAD(e."created_at") OVER (PARTITION BY e."session_id" ORDER BY e."created_at") AS "next_created_at",
        CAST(REGEXP_SUBSTR(e."uri", '/product/([0-9]+)', 1, 1, 'e', 1) AS INT) AS "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS e
    WHERE e."uri" ILIKE '%/product/%'
),
filtered AS (
    /* 3. Keep only product‑page views belonging to the top category and compute dwell time */
    SELECT
        p."category",
        (ewp."next_created_at" - ewp."created_at") / 60000000.0 AS "minutes_on_page"
    FROM events_with_product ewp
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
          ON ewp."product_id" = p."id"
    JOIN top_category tc
          ON p."category" = tc."category"
    WHERE ewp."next_created_at" IS NOT NULL
)
SELECT
    MIN("category")                          AS product_category_name,
    ROUND(AVG("minutes_on_page"), 4)         AS average_page_view_time_minutes
FROM filtered;