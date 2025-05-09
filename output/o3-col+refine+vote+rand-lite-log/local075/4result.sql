/*  Views, cart–adds, purchases and “left-in-cart” counts
    for every product page, excluding pages 1, 2, 12 and 13  */

WITH product_pages AS (
    SELECT "page_id",
           "product_id",
           "page_name"
    FROM   "shopping_cart_page_hierarchy"
    WHERE  "page_id" NOT IN (1,2,12,13)
),
views AS (
    SELECT p."product_id",
           COUNT(*) AS view_cnt
    FROM   "shopping_cart_events" AS e
    JOIN   product_pages          AS p
           ON e."page_id" = p."page_id"
    WHERE  e."event_type" = 1       -- page views
    GROUP BY p."product_id"
),
adds AS (
    SELECT p."product_id",
           COUNT(*) AS add_cnt
    FROM   "shopping_cart_events" AS e
    JOIN   product_pages          AS p
           ON e."page_id" = p."page_id"
    WHERE  e."event_type" = 2       -- add-to-cart actions
    GROUP BY p."product_id"
),
purch AS (
    SELECT p."product_id",
           COUNT(*) AS purchase_cnt
    FROM   "shopping_cart_events" AS e
    JOIN   product_pages          AS p
           ON e."page_id" = p."page_id"
    WHERE  e."event_type" = 3       -- completed purchases
    GROUP BY p."product_id"
)

SELECT pg."product_id",
       pg."page_name",
       COALESCE(v.view_cnt ,0)                                      AS views,
       COALESCE(a.add_cnt  ,0)                                      AS adds_to_cart,
       COALESCE(p.purchase_cnt,0)                                   AS purchases,
       MAX(COALESCE(a.add_cnt,0) - COALESCE(p.purchase_cnt,0), 0)   AS left_in_cart
FROM   product_pages AS pg
LEFT   JOIN views  AS v ON pg."product_id" = v."product_id"
LEFT   JOIN adds   AS a ON pg."product_id" = a."product_id"
LEFT   JOIN purch  AS p ON pg."product_id" = p."product_id"
ORDER  BY pg."product_id";