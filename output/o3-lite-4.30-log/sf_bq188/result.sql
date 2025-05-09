WITH top_category AS (   -- highest‑selling category
    SELECT p."category" AS product_category_name
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
          ON p."id" = oi."product_id"
    WHERE oi."status" IN ('Complete','Shipped')
    GROUP BY p."category"
    ORDER BY COUNT(*) DESC NULLS LAST, p."category"
    LIMIT 1
),
category_products AS (   -- product IDs in that category
    SELECT "id" AS product_id
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS
    WHERE "category" = (SELECT product_category_name FROM top_category)
),
page_views AS (          -- product page views with next event time
    SELECT
        e."session_id",
        TRY_TO_NUMBER(REGEXP_SUBSTR(e."uri", '\\d+'))      AS product_id,
        e."created_at"                                     AS view_time,
        LEAD(e."created_at") OVER (PARTITION BY e."session_id"
                                   ORDER BY e."created_at") AS next_event_time
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS e
    WHERE e."event_type" = 'product'
)
SELECT
    (SELECT product_category_name FROM top_category) AS product_category_name,
    ROUND(
        AVG( (next_event_time - view_time) / 1000000.0 / 60.0 ),
        4
    )                                               AS average_page_view_time_minutes
FROM page_views
WHERE product_id IN (SELECT product_id FROM category_products)
  AND next_event_time IS NOT NULL;