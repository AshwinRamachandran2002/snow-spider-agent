WITH views AS (
    SELECT p.product_id,
           COUNT(*) AS view_count
    FROM shopping_cart_events e
    JOIN shopping_cart_page_hierarchy p
      ON p.page_id = e.page_id
    WHERE e.event_type = 1
      AND e.page_id NOT IN (1,2,12,13)
    GROUP BY p.product_id
),
adds AS (
    SELECT e.visit_id,
           p.product_id,
           COUNT(*) AS add_events
    FROM shopping_cart_events e
    JOIN shopping_cart_page_hierarchy p
      ON p.page_id = e.page_id
    WHERE e.event_type = 2
      AND e.page_id NOT IN (1,2,12,13)
    GROUP BY e.visit_id, p.product_id
),
add_totals AS (
    SELECT product_id,
           SUM(add_events) AS add_to_cart_count
    FROM adds
    GROUP BY product_id
),
purchase_visits AS (
    SELECT DISTINCT visit_id
    FROM shopping_cart_events
    WHERE event_type = 3
),
purchases AS (
    SELECT a.product_id,
           COUNT(*) AS purchase_count
    FROM adds a
    WHERE a.visit_id IN (SELECT visit_id FROM purchase_visits)
    GROUP BY a.product_id
),
all_products AS (
    SELECT product_id FROM views
    UNION
    SELECT product_id FROM add_totals
    UNION
    SELECT product_id FROM purchases
)
SELECT
    ap.product_id,
    COALESCE(v.view_count,0)                       AS view_count,
    COALESCE(at.add_to_cart_count,0)               AS add_to_cart_count,
    COALESCE(at.add_to_cart_count,0) -
    COALESCE(p.purchase_count,0)                   AS cart_abandoned_count,
    COALESCE(p.purchase_count,0)                   AS purchase_count
FROM all_products ap
LEFT JOIN views      v  ON v.product_id  = ap.product_id
LEFT JOIN add_totals at ON at.product_id = ap.product_id
LEFT JOIN purchases  p  ON p.product_id  = ap.product_id
ORDER BY ap.product_id;