/*  Product‑level funnel metrics
    – views, add‑to‑cart, left‑in‑cart, purchases
    – page_id 1,2,12,13 removed                                           */

WITH filtered_events AS (
    SELECT  e.visit_id,
            e.page_id,
            ph.product_id,
            ph.page_name,
            e.event_type
    FROM    shopping_cart_events           AS e
    JOIN    shopping_cart_page_hierarchy   AS ph
           ON e.page_id = ph.page_id
    WHERE   e.page_id NOT IN (1,2,12,13)          -- remove non‑product pages
      AND   ph.product_id IS NOT NULL             -- keep only product rows
),

/* basic product reference (one name per product) */
prod_info AS (
    SELECT  product_id,
            MIN(page_name) AS product_name
    FROM    filtered_events
    GROUP BY product_id
),

/* raw event counts */
aggregates AS (
    SELECT  product_id,
            SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS views,
            SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,
            SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchases
    FROM    filtered_events
    GROUP BY product_id
),

/* “left in cart” = added to cart in a visit without a corresponding purchase */
left_cart AS (
    SELECT  a.product_id,
            COUNT(*) AS left_in_cart
    FROM   (SELECT DISTINCT visit_id, product_id
            FROM   filtered_events
            WHERE  event_type = 2)  AS a          -- distinct add‑to‑cart pairs
    LEFT JOIN
           (SELECT DISTINCT visit_id, product_id
            FROM   filtered_events
            WHERE  event_type = 3)  AS p          -- distinct purchase pairs
      ON  a.visit_id   = p.visit_id
     AND  a.product_id = p.product_id
    WHERE p.visit_id IS NULL                      -- no purchase happened
    GROUP BY a.product_id
)

SELECT  pi.product_id,
        pi.product_name,
        COALESCE(ag.views,        0) AS total_views,
        COALESCE(ag.add_to_cart,  0) AS total_add_to_cart,
        COALESCE(lc.left_in_cart, 0) AS total_left_in_cart,
        COALESCE(ag.purchases,    0) AS total_purchases
FROM    prod_info  AS pi
LEFT JOIN aggregates AS ag ON pi.product_id = ag.product_id
LEFT JOIN left_cart  AS lc ON pi.product_id = lc.product_id
ORDER BY pi.product_id;