SELECT
      p."product_id",
      SUM(CASE WHEN e."event_type" = 1 THEN 1 ELSE 0 END) AS "views",
      SUM(CASE WHEN e."event_type" = 2 THEN 1 ELSE 0 END) AS "add_to_cart",
      SUM(CASE WHEN e."event_type" = 3 THEN 1 ELSE 0 END) AS "purchases",
      SUM(CASE WHEN e."event_type" = 2 THEN 1 ELSE 0 END)
    - SUM(CASE WHEN e."event_type" = 3 THEN 1 ELSE 0 END) AS "left_in_cart"
FROM   "shopping_cart_events"          AS e
JOIN   "shopping_cart_page_hierarchy"  AS p
       ON e."page_id" = p."page_id"
WHERE  e."page_id" NOT IN (1, 2, 12, 13)
GROUP BY p."product_id"
ORDER BY p."product_id";