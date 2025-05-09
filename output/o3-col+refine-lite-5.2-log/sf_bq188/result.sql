/* ---------------------------------------------------------------
   1) Identify the product category with the highest purchase count
   2) For that category, calculate the average minutes spent on each
      product‑page view (time between a product‑page event and the
      very next event within the same session)
-----------------------------------------------------------------*/
WITH top_category AS (   -- step‑1 : best‑selling category
    SELECT p."category"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
           ON oi."product_id" = p."id"
    GROUP  BY p."category"
    ORDER  BY COUNT(*) DESC
    LIMIT  1
),
product_page_events AS (  -- all product‑page views + timestamp of next event
    SELECT
        e."session_id",
        e."created_at"                                        AS curr_ts,
        LEAD(e."created_at") OVER (PARTITION BY e."session_id"
                                   ORDER BY e."created_at")   AS next_ts,
        -- Extract numeric product‑ID from URIs like '/product/12345'
        TO_NUMBER(
            REGEXP_SUBSTR(e."uri", '/product/([0-9]+)', 1, 1, 'e', 1)
        )                                                     AS product_id
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE  e."uri" ILIKE '/product/%'
),
dwell_times AS (          -- minutes spent on each product page
    SELECT
        product_id,
        (next_ts - curr_ts) / 60000000.0  AS minutes_on_page
    FROM   product_page_events
    WHERE  next_ts IS NOT NULL            -- keep rows that have a "next" event
),
tie_to_category AS (      -- attach category information
    SELECT
        dt.minutes_on_page,
        p."category"
    FROM   dwell_times dt
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
           ON dt.product_id = p."id"
)
SELECT AVG(minutes_on_page) AS "avg_minutes_on_page"
FROM   tie_to_category
WHERE  "category" = (SELECT "category" FROM top_category);