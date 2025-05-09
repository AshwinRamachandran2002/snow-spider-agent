WITH category_purchases AS (
    /* 1. Total items purchased by category */
    SELECT
        p."category",
        COUNT(*) AS "total_items_purchased"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    GROUP BY p."category"
),
top_category AS (
    /* 2. Pick the single category with the highest purchase count */
    SELECT "category"
    FROM category_purchases
    ORDER BY "total_items_purchased" DESC NULLS LAST
    LIMIT 1
),
product_views AS (
    /* 3. All product-page views that belong to the top-purchased category,
           along with the timestamp of the next event in the same session   */
    SELECT
        e."session_id",
        e."created_at"                                                    AS "current_event_time",
        LEAD(e."created_at") OVER (PARTITION BY e."session_id"
                                   ORDER BY e."created_at")               AS "next_event_time"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS"   e
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON p."id" = TRY_TO_NUMBER(SPLIT_PART(e."uri", '/', 3))
    JOIN top_category tc
          ON p."category" = tc."category"
    WHERE e."event_type" = 'product'
)
SELECT
    (SELECT "category" FROM top_category)                                 AS "category_with_highest_purchases",
    AVG((pv."next_event_time" - pv."current_event_time")/60000000.0)      AS "avg_minutes_spent_per_product_page"
FROM product_views pv
WHERE pv."next_event_time" IS NOT NULL;