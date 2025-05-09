WITH product_events AS (
    SELECT
        ph.product_id,
        ph.page_name,
        e.event_type
    FROM shopping_cart_events            AS e
    JOIN shopping_cart_page_hierarchy    AS ph
          ON e.page_id = ph.page_id
    -- ignore non‑product pages
    WHERE e.page_id NOT IN (1, 2, 12, 13)
),
event_totals AS (
    SELECT
        product_id,
        page_name,
        SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS view_cnt,
        SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart_cnt,
        SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase_cnt
    FROM product_events
    GROUP BY product_id, page_name
)
SELECT
    product_id,
    page_name,
    view_cnt          AS views,
    add_to_cart_cnt   AS add_to_cart,
    CASE 
        WHEN add_to_cart_cnt > purchase_cnt 
        THEN add_to_cart_cnt - purchase_cnt 
        ELSE 0 
    END               AS left_in_cart,
    purchase_cnt      AS purchases
FROM event_totals
ORDER BY product_id;