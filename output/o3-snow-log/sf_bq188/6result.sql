/*  Identify the best-selling product category
    and compute the average minutes a user spends
    on each product page visit for that category  */

WITH top_category AS (          -- 1. category with highest purchased quantity
    SELECT
        p."category",
        COUNT(*) AS total_qty
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON oi."product_id" = p."id"
    GROUP BY p."category"
    ORDER BY total_qty DESC NULLS LAST
    LIMIT 1
),

product_page_views AS (        -- 2. every product-page view (extract product_id from URI)
    SELECT
        e."session_id",
        e."created_at",
        TRY_TO_NUMBER(REGEXP_SUBSTR(e."uri", '\\d+')) AS product_id
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE e."uri" ILIKE '/product%'                    -- URIs that begin with /product
          AND TRY_TO_NUMBER(REGEXP_SUBSTR(e."uri", '\\d+')) IS NOT NULL
),

category_product_views AS (    -- 3. views belonging to the top-selling category
    SELECT
        ppv."session_id",
        ppv."created_at",
        p."category"
    FROM product_page_views ppv
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON ppv.product_id = p."id"
    JOIN top_category tc
          ON p."category" = tc."category"
),

session_events AS (            -- 4. for every event get the next event in its session
    SELECT
        e."session_id",
        e."created_at",
        LEAD(e."created_at")
          OVER (PARTITION BY e."session_id" ORDER BY e."created_at") AS "next_created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
),

time_deltas AS (               -- 5. time (in minutes) from page view to next session event
    SELECT
        cpv."category",
        (se."next_created_at" - cpv."created_at") / 60000000.0 AS minutes_spent
    FROM category_product_views cpv
    JOIN session_events       se
      ON se."session_id" = cpv."session_id"
     AND se."created_at" = cpv."created_at"
    WHERE se."next_created_at" IS NOT NULL
      AND (se."next_created_at" - cpv."created_at") > 0
)

SELECT
    (SELECT "category" FROM top_category)  AS "CATEGORY_WITH_HIGHEST_PURCHASE_QTY",
    ROUND(AVG(minutes_spent), 4)           AS "AVG_MINUTES_SPENT_PER_PRODUCT_PAGE"
FROM time_deltas;