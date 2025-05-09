WITH filtered_events AS (
    /* keep only events that belong to a real product page
       and remove generic/navigation pages 1,2,12,13           */
    SELECT 
        p.product_id,
        e.event_type
    FROM shopping_cart_events           AS e
    JOIN shopping_cart_page_hierarchy   AS p
         ON e.page_id = p.page_id
    WHERE p.product_id IS NOT NULL
      AND e.page_id NOT IN (1,2,12,13)
),
event_totals AS (
    /* aggregate counts for each kind of event per product */
    SELECT
        product_id,
        SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS views_cnt,
        SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_cnt,
        SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_cnt
    FROM filtered_events
    GROUP BY product_id
)
SELECT
    product_id,
    views_cnt           AS page_views,
    add_to_cart_cnt     AS add_to_cart,
    /* items left in cart = added ‑ purchased (never negative) */
    CASE 
        WHEN add_to_cart_cnt > purchase_cnt 
        THEN add_to_cart_cnt - purchase_cnt
        ELSE 0
    END                AS left_in_cart,
    purchase_cnt        AS purchases
FROM event_totals
ORDER BY product_id;