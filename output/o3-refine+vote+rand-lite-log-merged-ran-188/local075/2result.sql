WITH filtered_pages AS (
    -- keep only actual product pages
    SELECT page_id,
           product_id,
           page_name
    FROM   shopping_cart_page_hierarchy
    WHERE  page_id NOT IN (1,2,12,13)
),
event_totals AS (
    -- count each type of event per product
    SELECT  fp.product_id,
            e.event_type,
            COUNT(*) AS cnt
    FROM    shopping_cart_events AS e
    JOIN    filtered_pages      AS fp
           ON e.page_id = fp.page_id
    WHERE   e.event_type IN (1,2,3)          -- 1-view, 2-add, 3-purchase
    GROUP BY fp.product_id,
             e.event_type
),
pivot AS (
    -- pivot the three event counts side-by-side
    SELECT  fp.product_id,
            fp.page_name,
            COALESCE(SUM(CASE WHEN et.event_type = 1 THEN et.cnt END),0) AS view_count,
            COALESCE(SUM(CASE WHEN et.event_type = 2 THEN et.cnt END),0) AS add_cart_count,
            COALESCE(SUM(CASE WHEN et.event_type = 3 THEN et.cnt END),0) AS purchase_count
    FROM    filtered_pages AS fp
    LEFT JOIN event_totals AS et
           ON fp.product_id = et.product_id
    GROUP BY fp.product_id,
             fp.page_name
)
SELECT  product_id,
        page_name,
        view_count,
        add_cart_count,
        purchase_count,
        (add_cart_count - purchase_count) AS left_in_cart
FROM    pivot
ORDER BY left_in_cart DESC;