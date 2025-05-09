WITH top_category AS (
    -- 1) find the category with the greatest number of purchased order-items
    SELECT p."category"
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"      p
           ON p."id" = oi."product_id"
    GROUP  BY p."category"
    ORDER  BY COUNT(oi."id") DESC NULLS LAST
    LIMIT  1
),
page_views AS (
    -- 2) capture every product-page view together with the timestamp
    SELECT
        e."session_id",
        TRY_TO_NUMBER(
            REGEXP_SUBSTR(e."uri", '/product/([0-9]+)', 1, 1, 'e', 1)
        )                         AS "product_id",
        e."created_at"            AS "view_time",
        LEAD(e."created_at")
          OVER (PARTITION BY e."session_id" ORDER BY e."created_at")
                                   AS "next_event_time"
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS" e
    WHERE  e."uri" ILIKE '%/product/%'
),
view_durations AS (
    -- 3) compute time-on-page in minutes (exclude last event in a session)
    SELECT
        pv."product_id",
        (pv."next_event_time" - pv."view_time") / 60000000.0  AS "minutes_on_page"
    FROM   page_views pv
    WHERE  pv."next_event_time" IS NOT NULL
)
-- 4) average minutes per product view for the single top-selling category
SELECT
    tc."category"                           AS "top_category",
    AVG(vd."minutes_on_page")               AS "avg_minutes_per_product_view"
FROM        view_durations vd
JOIN        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
              ON p."id" = vd."product_id"
JOIN        top_category tc
              ON p."category" = tc."category"
GROUP BY    tc."category";