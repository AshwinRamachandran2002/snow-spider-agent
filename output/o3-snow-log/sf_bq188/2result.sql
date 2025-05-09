WITH category_qty AS (          -- 1. total purchased quantity for every product category
    SELECT  p."category",
            COUNT(oi."id") AS qty
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
           ON oi."product_id" = p."id"
    GROUP BY p."category"
),                                                         
top_category AS (        -- 2. keep only the category with the highest quantity
    SELECT  "category"
    FROM    category_qty
    ORDER BY qty DESC NULLS LAST
    LIMIT 1
),                                                         
product_page_events AS ( -- 3. every “product page view” event (uri contains /product or /products)
    SELECT  e."session_id",
            e."created_at",
            TO_NUMBER( REGEXP_SUBSTR(e."uri" , '/product[s]?/([0-9]+)', 1 , 1 , 'e' , 1) ) AS product_id,
            LEAD(e."created_at") 
                OVER (PARTITION BY e."session_id" ORDER BY e."created_at") AS next_created_at
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS"  e
    WHERE   REGEXP_LIKE(e."uri", '/product[s]?/([0-9]+)')
),                                                         
durations AS (           -- 4. duration (in minutes) each time a product page of the top category is viewed
    SELECT  ppe."created_at",
            ( ppe.next_created_at - ppe."created_at") / 1000000.0 / 60   AS minutes_spent
    FROM    product_page_events      ppe
    JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" prod
           ON ppe.product_id = prod."id"
    JOIN    top_category tc
           ON prod."category" = tc."category"
    WHERE   ppe.next_created_at IS NOT NULL        -- need a “next” event to get the time spent
)
-- 5. final result: top category and average minutes spent on its product pages
SELECT  tc."category"                                       AS top_category,
        ROUND( AVG(d.minutes_spent) , 4)                    AS avg_minutes_spent_per_product_view
FROM    top_category tc
JOIN    durations     d   ON 1=1
GROUP BY tc."category";