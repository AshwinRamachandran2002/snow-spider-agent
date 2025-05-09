/* ----------------------------------------------------------
   1)  Determine the product category with the largest number
       of purchased items (exclude cancelled line-items).
   2)  For that top category, calculate the average number of
       minutes between a product-page view and the very next
       event in the same session.
---------------------------------------------------------------- */
WITH category_quantity AS (               -- total items bought per category
    SELECT  p."category",
            COUNT(*) AS total_items
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON oi."product_id" = p."id"
    WHERE   oi."status" <> 'Cancelled'
    GROUP BY p."category"
),

top_category AS (                         -- category with the highest quantity
    SELECT  "category"
    FROM    category_quantity
    ORDER BY total_items DESC NULLS LAST
    LIMIT 1
),

product_page_events AS (                  -- every product-page view + next event
    SELECT  e."session_id",
            e."created_at"                                   AS event_time,
            TRY_TO_NUMBER(REGEXP_SUBSTR(e."uri",
                                         '/products/([0-9]+)',
                                         1, 1, 'e', 1))      AS product_id,
            LEAD(e."created_at") OVER (PARTITION BY e."session_id"
                                        ORDER BY e."created_at") AS next_event_time
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE   e."uri" ILIKE '/products/%'
),

durations AS (                            -- minutes spent on each product page
    SELECT  product_id,
            (next_event_time - event_time) / 60000000.0  AS minutes_spent     -- µs → minutes
    FROM    product_page_events
    WHERE   next_event_time IS NOT NULL
      AND   product_id       IS NOT NULL
),

filtered_durations AS (                   -- only views for products in top category
    SELECT  d.minutes_spent
    FROM    durations d
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
           ON d.product_id = p."id"
    JOIN    top_category tc
           ON p."category" = tc."category"
    WHERE   d.minutes_spent > 0
)

SELECT  tc."category"                                         AS top_category,
        ROUND(AVG(fd.minutes_spent), 4)                       AS avg_minutes_per_product_page_visit
FROM    top_category        tc
LEFT JOIN filtered_durations fd
       ON 1 = 1
GROUP BY tc."category";