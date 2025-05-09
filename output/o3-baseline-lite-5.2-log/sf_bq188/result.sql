WITH top_category AS (   -- 1. find the category with the largest purchase quantity
    SELECT 
        p."category",
        COUNT(*)                AS total_qty
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    GROUP BY p."category"
    ORDER BY total_qty DESC NULLS LAST
    LIMIT 1
),

product_page_events AS (  -- 2. keep only product‑page views (URI starts with /products/)
    SELECT 
        e."session_id",
        e."created_at",
        TRY_TO_NUMBER( SPLIT_PART(e."uri", '/', 3) ) AS product_id     -- extract the product id
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE e."uri" LIKE '/products/%'
),

filtered_events AS (      -- 3. retain events whose product belongs to the top category
    SELECT 
        ppe."session_id",
        ppe."created_at"
    FROM product_page_events                ppe
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON ppe.product_id = p."id"
    JOIN top_category tc
          ON p."category"  = tc."category"
),

events_with_next AS (     -- 4. find the next event (any type) within the same session
    SELECT
        fe."session_id",
        fe."created_at",
        LEAD(fe."created_at") OVER (PARTITION BY fe."session_id" 
                                    ORDER BY fe."created_at") AS next_created_at
    FROM filtered_events fe
),

durations AS (             -- 5. compute time spent in minutes (exclude last page in a session)
    SELECT
        DATEDIFF(
            'minute',
            TO_TIMESTAMP_LTZ("created_at"    / 1000000),      -- micro‑seconds → seconds
            TO_TIMESTAMP_LTZ(next_created_at / 1000000)
        ) AS minutes_spent
    FROM events_with_next
    WHERE next_created_at IS NOT NULL
)

SELECT
    (SELECT "category" FROM top_category) AS "top_purchase_category",
    AVG(minutes_spent)                   AS "avg_minutes_per_product_page_visit"
FROM durations;