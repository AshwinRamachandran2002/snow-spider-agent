WITH purchase_counts AS (
    SELECT
        p."category",
        COUNT(oi."id") AS total_purchase_qty
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    GROUP BY p."category"
),

top_category AS (          -- category with the largest purchase quantity
    SELECT "category"
    FROM   purchase_counts
    ORDER  BY total_purchase_qty DESC NULLS LAST
    LIMIT  1
),

product_page_events AS (   -- every product-page view (URI contains “/products/<id>”)
    SELECT
        e."session_id",
        e."created_at",
        CAST( REGEXP_SUBSTR(e."uri", '/products/([0-9]+)', 1, 1, 'e', 1) AS NUMBER )  AS product_id
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE REGEXP_LIKE(e."uri", '/products/[0-9]+')
),

filtered_events AS (       -- keep only product-page views that belong to the top category
    SELECT
        ppe."session_id",
        ppe."created_at"
    FROM product_page_events            ppe
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON ppe.product_id = p."id"
    JOIN top_category tc
          ON p."category"  = tc."category"
),

event_durations AS (       -- time (minutes) until the next event in the same session
    SELECT
        "session_id",
        ( LEAD("created_at") OVER (PARTITION BY "session_id"
                                   ORDER BY "created_at")
          - "created_at" ) / 60000000.0     AS minutes_spent
    FROM filtered_events
)

SELECT
    (SELECT "category" FROM top_category)         AS category_with_highest_purchase_quantity,
    AVG(minutes_spent)                            AS avg_minutes_per_product_page_visit
FROM event_durations
WHERE minutes_spent IS NOT NULL;