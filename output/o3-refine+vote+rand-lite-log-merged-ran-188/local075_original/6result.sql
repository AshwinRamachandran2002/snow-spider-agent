WITH events_filtered AS (
    /* keep only true product pages and exclude the pages 1,2,12,13 */
    SELECT  e.visit_id,
            ph.product_id,
            e.event_type
    FROM    shopping_cart_events           AS e
    JOIN    shopping_cart_page_hierarchy   AS ph
           ON e.page_id = ph.page_id
    WHERE   e.page_id NOT IN (1,2,12,13)
      AND   ph.product_id IS NOT NULL
),
product_level_counts AS (
    /* basic counts for page‑views, add‑to‑cart actions and purchases            */
    SELECT  product_id,
            SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS views,
            SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,
            SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchases
    FROM    events_filtered
    GROUP BY product_id
),
left_in_cart AS (
    /* a visit/product pair is “left in cart” when it has at least one
       add‑to‑cart but zero purchases                                            */
    SELECT  product_id,
            COUNT(*) AS left_in_cart_without_purchase
    FROM   (
            SELECT  visit_id,
                    product_id
            FROM    events_filtered
            GROUP BY visit_id, product_id
            HAVING  SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) > 0
               AND  SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) = 0
           )
    GROUP BY product_id
)

SELECT  plc.product_id,
        plc.views,
        plc.add_to_cart,
        COALESCE(lc.left_in_cart_without_purchase,0) AS left_in_cart_without_purchase,
        plc.purchases
FROM    product_level_counts  AS plc
LEFT JOIN left_in_cart        AS lc
       USING (product_id)
ORDER BY plc.product_id;