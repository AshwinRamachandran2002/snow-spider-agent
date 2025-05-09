SELECT
    ph.product_id,
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END)                                   AS view_count,
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END)                                   AS add_to_cart_count,
    CASE
        WHEN SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) -
             SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) > 0
        THEN SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) -
             SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END)
        ELSE 0
    END                                                                                 AS left_in_cart_without_purchase,
    SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END)                                   AS purchase_count
FROM shopping_cart_events              AS e
JOIN shopping_cart_page_hierarchy      AS ph  ON e.page_id = ph.page_id
WHERE e.page_id NOT IN (1, 2, 12, 13)          -- exclude non‑product pages
  AND ph.product_id IS NOT NULL                -- keep only rows tied to a product
GROUP BY ph.product_id
ORDER BY ph.product_id;