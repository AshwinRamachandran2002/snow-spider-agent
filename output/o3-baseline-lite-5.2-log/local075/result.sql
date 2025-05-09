WITH filtered_events AS (
    SELECT  e.visit_id,
            e.cookie_id,
            e.page_id,
            e.event_type,
            ph.product_id
    FROM    shopping_cart_events            AS e
    JOIN    shopping_cart_page_hierarchy    AS ph
           ON ph.page_id = e.page_id
    -- Exclude generic / non‑product pages
    WHERE   e.page_id NOT IN (1, 2, 12, 13)
), event_counts AS (
    SELECT  product_id,
            SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS views,
            SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,
            SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchases
    FROM    filtered_events
    GROUP BY product_id
)
SELECT  product_id,
        views,
        add_to_cart,
        /* items added but never purchased */
        CASE 
            WHEN add_to_cart - purchases > 0 THEN add_to_cart - purchases 
            ELSE 0 
        END                         AS left_in_cart,
        purchases
FROM    event_counts
ORDER BY product_id;