SELECT
    h."product_id",
    COUNT(CASE WHEN e."event_type" = 1 THEN 1 END) AS view_count,
    COUNT(CASE WHEN e."event_type" = 2 THEN 1 END) AS add_to_cart_count,
    COUNT(CASE WHEN e."event_type" = 2 THEN 1 END)
      - COUNT(CASE WHEN e."event_type" = 3 THEN 1 END) AS cart_abandoned_count,
    COUNT(CASE WHEN e."event_type" = 3 THEN 1 END) AS purchase_count
FROM "shopping_cart_events" AS e
JOIN "shopping_cart_page_hierarchy" AS h
  ON e."page_id" = h."page_id"
WHERE e."page_id" NOT IN (1, 2, 12, 13)
GROUP BY h."product_id"
ORDER BY view_count DESC;