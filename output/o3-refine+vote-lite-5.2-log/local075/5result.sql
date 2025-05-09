WITH event_details AS (
    /* link every event to its product and discard the generic pages */
    SELECT
        sch.product_id,
        sce.event_type
    FROM shopping_cart_events AS sce
    JOIN shopping_cart_page_hierarchy AS sch
         ON sce.page_id = sch.page_id
    WHERE sce.page_id NOT IN (1, 2, 12, 13)          -- remove generic pages
      AND sch.product_id IS NOT NULL                 -- keep only real products
),
event_summary AS (
    /* aggregate event counts per product */
    SELECT
        product_id,
        SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS views,
        SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,
        SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchases
    FROM event_details
    GROUP BY product_id
)
SELECT
    product_id,
    views,
    add_to_cart,
    /* items added but never purchased */
    MAX(add_to_cart - purchases, 0)     AS left_in_cart,
    purchases
FROM event_summary
ORDER BY product_id;