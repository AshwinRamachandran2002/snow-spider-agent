WITH valid_order_items AS (   -- all purchased items, excluding cancellations
    SELECT "product_id"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"
    WHERE "status" <> 'Cancelled'
), 
    
category_sales AS (          -- total quantity sold per category
    SELECT  p."category",
            COUNT(*) AS purchase_qty
    FROM    valid_order_items v
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
        ON  v."product_id" = p."id"
    GROUP BY p."category"
),        

top_category AS (            -- category with the highest quantity
    SELECT  "category"
    FROM    category_sales
    ORDER BY purchase_qty DESC NULLS LAST
    LIMIT 1
),        

product_events AS (          -- all product-page visits, capturing product_id
    SELECT  e."session_id",
            e."created_at",
            CAST(REGEXP_SUBSTR(e."uri", '/product/([0-9]+)', 1, 1, 'e', 1) AS NUMBER) AS product_id
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS" e
    WHERE   REGEXP_LIKE(e."uri", '/product/[0-9]+')
),        

category_product_events AS ( -- product-page visits that belong to the top category
    SELECT  pe."session_id",
            pe."created_at",
            LEAD(pe."created_at") 
              OVER (PARTITION BY pe."session_id" ORDER BY pe."created_at") AS next_created_at
    FROM    product_events pe
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
        ON  pe.product_id = p."id"
    JOIN    top_category tc
        ON  p."category" = tc."category"
),        

durations AS (               -- time spent on each product page (µs) 
    SELECT  (next_created_at - "created_at") AS duration_micro
    FROM    category_product_events
    WHERE   next_created_at IS NOT NULL
            AND next_created_at > "created_at"
)        

SELECT  (SELECT "category" FROM top_category)        AS "top_category",
        ROUND(AVG(duration_micro / 1000000 / 60),4)  AS "avg_time_minutes"
FROM    durations;