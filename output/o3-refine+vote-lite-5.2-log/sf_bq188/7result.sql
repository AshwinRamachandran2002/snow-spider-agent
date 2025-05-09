/* 1. Find the product‑category with the greatest number of purchased
      (non‑cancelled) order‑items
   2. For that category, take every product‑page visit
      (URI like /product(s)/<product_id>)
      and work out the time until the very next event in the same session
   3. Return the category and the average of those time‑differences in minutes  */

WITH category_purchase AS (                -- step‑1 : biggest‑selling category
    SELECT
        p."category",
        COUNT(*) AS "total_qty"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
      ON oi."product_id" = p."id"
    WHERE oi."status" <> 'Cancelled'
    GROUP BY p."category"
    ORDER BY "total_qty" DESC NULLS LAST
    LIMIT 1
),

product_page_events AS (                   -- step‑2a : every product‑page event
    SELECT
        e."session_id",
        e."created_at"                                                            AS "this_time",
        LEAD(e."created_at") OVER (PARTITION BY e."session_id"
                                   ORDER BY e."created_at")                       AS "next_time",
        TO_NUMBER(                                                               -- extract product_id
            REGEXP_SUBSTR(e."uri",
                          '/(products|product)/([0-9]+)',           -- get digits
                          1, 1, 'e', 2)
        )                                                                        AS "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE REGEXP_LIKE(e."uri", '/(products|product)/[0-9]+')
),

filtered_events AS (                        -- step‑2b : keep only wanted category
    SELECT
        ppe."this_time",
        ppe."next_time"
    FROM product_page_events               ppe
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" pr
      ON ppe."product_id" = pr."id"
    JOIN category_purchase                 cp
      ON pr."category" = cp."category"
    WHERE ppe."next_time" IS NOT NULL      -- ignore last event of a session
)

SELECT
    cp."category",
    AVG( (fe."next_time" - fe."this_time") / 60000000.0 )  AS "avg_minutes_per_product_page"
FROM filtered_events           fe
CROSS JOIN category_purchase   cp                          -- only one row
GROUP BY cp."category";