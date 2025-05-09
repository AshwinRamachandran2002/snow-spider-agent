WITH purchase_cte AS (          -- 1. total quantity purchased per category
    SELECT  p."category",
            COUNT(oi."id") AS total_qty
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
           ON oi."product_id" = p."id"
    WHERE   COALESCE(UPPER(oi."status"),'') <> 'CANCELLED'
    GROUP BY p."category"
),  

top_category AS (               -- 2. category with the highest quantity
    SELECT  "category"
    FROM    purchase_cte
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_qty DESC NULLS LAST) = 1
),

product_events AS (             -- 3. events that represent a product-page view
    SELECT  e."session_id",
            e."created_at"  AS event_time,
            TRY_TO_NUMBER(
                REGEXP_SUBSTR(e."uri", '/product/(\\d+)', 1, 1, 'e', 1)
            )                 AS product_id
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS" e
    WHERE   REGEXP_LIKE(e."uri", '/product/\\d+')
),

category_events AS (            -- 4. events for products in the top-purchase category
    SELECT  pe."session_id",
            pe.event_time,
            LEAD(pe.event_time)
              OVER (PARTITION BY pe."session_id"
                    ORDER BY     pe.event_time) AS next_event_time
    FROM    product_events  pe
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"  p
           ON pe.product_id = p."id"
    JOIN    top_category  tc
           ON p."category" = tc."category"
)

-- 5. average minutes spent on a product page for the category with max purchases
SELECT  (SELECT "category" FROM top_category)           AS category_with_max_purchases,
        ROUND(AVG( (ce.next_event_time - ce.event_time) / 60000000.0 ), 4)
                                                      AS avg_minutes_on_product_page
FROM    category_events  ce
WHERE   ce.next_event_time IS NOT NULL;