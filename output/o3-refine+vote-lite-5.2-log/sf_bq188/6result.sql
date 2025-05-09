WITH top_category AS (      -- 1.  find the category with the largest number of purchased items
    SELECT 
        p."category",
        COUNT(*)   AS "total_quantity"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" NOT ILIKE 'Cancelled%'                -- treat non‑cancelled rows as purchases
    GROUP BY p."category"
    QUALIFY ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) = 1  -- keep only the top‑selling category
), category_products AS (     -- 2.  all products that belong to that category
    SELECT p."id" AS "product_id"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    JOIN   top_category tc
           ON p."category" = tc."category"
), product_page_events AS (   -- 3.  every product‑page visit in Events
    SELECT
        e."session_id",
        e."created_at",
        /* product id appears at the end of URIs such as '/product/12345' */
        CAST(REGEXP_SUBSTR(e."uri", '/product/([0-9]+)', 1, 1, 'e', 1) AS NUMBER) AS "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE e."uri" ILIKE '/product/%'
), target_events AS (         -- 4.  only product‑page visits from the top category
    SELECT
        pe."session_id",
        pe."created_at",
        LEAD(pe."created_at")  OVER (PARTITION BY pe."session_id"
                                     ORDER BY    pe."created_at")        AS "next_created_at"
    FROM   product_page_events  pe
    JOIN   category_products    cp
           ON pe."product_id" = cp."product_id"
), durations AS (             -- 5.  time spent on each qualifying product page (minutes)
    SELECT 
        ("next_created_at" - "created_at") / 60000000.0  AS "minutes_spent"
    FROM target_events
    WHERE "next_created_at" IS NOT NULL                  -- ignore page views that were the last in session
)
SELECT 
    (SELECT "category" FROM top_category)                            AS "top_category_by_quantity",
    AVG("minutes_spent")                                             AS "avg_minutes_per_product_page_visit"
FROM durations;