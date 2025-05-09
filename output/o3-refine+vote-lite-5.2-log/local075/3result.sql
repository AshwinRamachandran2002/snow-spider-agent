SELECT
    p."product_id",
    p."page_name",
    p."product_category",
    SUM(CASE WHEN e."event_type" = 1 THEN 1 ELSE 0 END)                                   AS view_count,
    SUM(CASE WHEN e."event_type" = 2 THEN 1 ELSE 0 END)                                   AS add_to_cart_count,
    SUM(CASE WHEN e."event_type" = 3 THEN 1 ELSE 0 END)                                   AS purchase_count,
    CASE
        WHEN (SUM(CASE WHEN e."event_type" = 2 THEN 1 ELSE 0 END) -
              SUM(CASE WHEN e."event_type" = 3 THEN 1 ELSE 0 END)) < 0
        THEN 0
        ELSE (SUM(CASE WHEN e."event_type" = 2 THEN 1 ELSE 0 END) -
              SUM(CASE WHEN e."event_type" = 3 THEN 1 ELSE 0 END))
    END                                                                                    AS left_in_cart_count
FROM "shopping_cart_events"            AS e
JOIN "shopping_cart_page_hierarchy"    AS p
     ON e."page_id" = p."page_id"
WHERE e."page_id" NOT IN (1, 2, 12, 13)          -- remove non‑product pages
  AND p."product_id" IS NOT NULL                 -- keep only rows that map to a product
GROUP BY p."product_id", p."page_name", p."product_category"
ORDER BY p."product_id";