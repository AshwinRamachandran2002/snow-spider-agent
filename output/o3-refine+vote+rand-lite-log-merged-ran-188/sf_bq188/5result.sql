/* -----------------------------------------------------------
   1) Determine the product category with the largest number of
      purchased (status = 'Complete') items.
   2) For that category, calculate the average minutes a user
      spends on each product‑detail page.  “Time on page” =
      time from the page‑view event (event_type = 'page_view',
      uri like '/products/%') to the very next event in the
      same session.                                             
   ----------------------------------------------------------- */

WITH product_category_totals AS (          -- total purchased‑item count per category
    SELECT  p."category",
            COUNT(*) AS qty
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
           ON oi."product_id" = p."id"
    WHERE   oi."status" = 'Complete'
    GROUP BY p."category"
),

top_category AS (                          -- the single most‑purchased category
    SELECT  "category"
    FROM    product_category_totals
    ORDER BY qty DESC
    LIMIT 1
),

top_category_products AS (                 -- product IDs belonging to that category
    SELECT  p."id"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    JOIN    top_category tc
          ON p."category" = tc."category"
),

product_page_views AS (                    -- all product‑page views
    SELECT  e."session_id",
            e."user_id",
            e."created_at",
            TRY_TO_NUMBER(
                REGEXP_SUBSTR(e."uri",
                              '/products/([0-9]+)',
                              1, 1, 'e', 1)          -- capture product_id from URL
            ) AS product_id
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
    WHERE   e."event_type" = 'page_view'
      AND   e."uri"        LIKE '/products/%'
),

page_views_top_category AS (               -- only views of products in top category
    SELECT *
    FROM   product_page_views
    WHERE  product_id IN (SELECT "id" FROM top_category_products)
),

views_with_next_event AS (                 -- append timestamp of the next event
    SELECT  v.*,
            LEAD(v."created_at") OVER (PARTITION BY v."session_id"
                                       ORDER BY v."created_at") AS next_created_at
    FROM    page_views_top_category v
),

durations AS (                             -- minutes spent on each product page
    SELECT  (next_created_at - "created_at") / 1000000.0 / 60.0 AS minutes_spent
    FROM    views_with_next_event
    WHERE   next_created_at IS NOT NULL
)

SELECT
    (SELECT "category" FROM top_category)  AS top_purchase_category,
    AVG(minutes_spent)                     AS avg_minutes_on_product_page
FROM durations;