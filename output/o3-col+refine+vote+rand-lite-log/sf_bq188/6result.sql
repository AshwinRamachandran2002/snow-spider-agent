WITH completed_sales AS (          -- total purchase quantity per category
    SELECT  p."category",
            COUNT(*) AS purchase_qty
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
           ON p."id" = oi."product_id"
    WHERE   oi."status" ILIKE '%Complete%'
    GROUP BY p."category"
),

top_category AS (                  -- category with the highest purchase_qty
    SELECT  "category"
    FROM    completed_sales
    ORDER BY purchase_qty DESC NULLS LAST
    LIMIT 1
),

top_category_products AS (         -- every product id that belongs to that category
    SELECT "id" AS product_id
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS
    WHERE  "category" IN (SELECT "category" FROM top_category)
),

product_page_events AS (           -- product-page views for those products
    SELECT  e."session_id",
            e."created_at"                         AS view_ts,
            LEAD(e."created_at")
              OVER (PARTITION BY e."session_id"
                    ORDER BY e."created_at")       AS next_ts
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS e
    JOIN    top_category_products tcp
           ON TRY_TO_NUMBER(SPLIT_PART(e."uri", '/', 3)) = tcp.product_id
    WHERE   e."event_type" = 'product'
),

durations AS (                     -- minutes between view and next event
    SELECT  (next_ts - view_ts) / 60000000.0 AS minutes_spent
    FROM    product_page_events
    WHERE   next_ts IS NOT NULL
)

SELECT  (SELECT "category" FROM top_category)     AS category_with_max_purchases,
        AVG(minutes_spent)                        AS avg_minutes_per_product_page
FROM    durations;