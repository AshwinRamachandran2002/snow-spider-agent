WITH category_sales AS (   /* 1. Total quantity sold per product category */
    SELECT 
        p."category",
        COUNT(*) AS "total_qty"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    GROUP BY p."category"
),  

top_category AS (          /* 2. Category with the highest total purchases */
    SELECT "category"
    FROM category_sales
    ORDER BY "total_qty" DESC NULLS LAST
    LIMIT 1
),  

product_page_events AS (   /* 3. All product-page views with a parsable product_id */
    SELECT
        e."session_id",
        e."created_at",
        TRY_TO_NUMBER(
            REGEXP_SUBSTR(e."uri", '/product/([0-9]+)', 1, 1, 'e', 1)
        ) AS "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE e."uri" LIKE '/product/%'
      AND TRY_TO_NUMBER(
            REGEXP_SUBSTR(e."uri", '/product/([0-9]+)', 1, 1, 'e', 1)
          ) IS NOT NULL
),  

product_events_with_cat AS (  /* 4. Attach category to each product-page view */
    SELECT
        ppe."session_id",
        ppe."created_at",
        ppe."product_id",
        pr."category"
    FROM product_page_events              ppe
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" pr
          ON ppe."product_id" = pr."id"
),  

filtered_events AS (        /* 5. Keep only events for the top-selling category */
    SELECT fe.*
    FROM product_events_with_cat fe
    JOIN top_category tc
      ON fe."category" = tc."category"
),  

timed_events AS (           /* 6. Time spent on each product page (to next event) */
    SELECT
        "session_id",
        "created_at",
        LEAD("created_at") OVER (PARTITION BY "session_id" 
                                 ORDER BY "created_at") AS "next_created_at"
    FROM filtered_events
)  

/* 7. Final answer: average minutes spent on a product page for the top category */
SELECT
    (SELECT "category" FROM top_category)            AS "top_category",
    AVG( ("next_created_at" - "created_at") / 1000000.0 / 60.0 ) 
                                                    AS "avg_minutes_per_product_page"
FROM timed_events
WHERE "next_created_at" IS NOT NULL;