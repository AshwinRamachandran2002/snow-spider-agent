WITH top_category AS (          /* 1. category with the most completed‑order items */
    SELECT 
        p."category",
        COUNT(*) AS total_qty
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"    p
          ON oi."product_id" = p."id"
    WHERE oi."status" = 'Complete'
    GROUP BY p."category"
    ORDER BY total_qty DESC NULLS LAST, p."category"
    LIMIT 1
),

top_category_products AS (      /* 2. all product IDs in that category            */
    SELECT p."id"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    JOIN   top_category tc
           ON p."category" = tc."category"
),

product_page_events AS (        /* 3. product page views + next event in session  */
    SELECT
        e."session_id",
        e."created_at"                                                     AS "this_time",
        LEAD(e."created_at") OVER (PARTITION BY e."session_id"
                                   ORDER BY e."created_at")                AS "next_time",
        TRY_TO_NUMBER(REGEXP_SUBSTR(e."uri", '[0-9]+'))                    AS product_id
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE e."uri" ILIKE '%/product/%'
),

dwell_times AS (                 /* 4. dwell (minutes) on products in top category */
    SELECT 
        tc."category",
        ("next_time" - "this_time") / 60000000.0   AS minutes_spent   /* µs ➜ minutes */
    FROM product_page_events      pp
    JOIN top_category_products    tp   ON pp.product_id = tp."id"
    JOIN top_category             tc   ON 1=1
    WHERE pp."next_time" IS NOT NULL
)

SELECT
    "category",
    ROUND(AVG(minutes_spent), 4) AS avg_minutes_spent_per_product_view
FROM dwell_times
GROUP BY "category";