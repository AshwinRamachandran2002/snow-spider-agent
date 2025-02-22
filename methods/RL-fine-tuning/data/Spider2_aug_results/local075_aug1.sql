-- Task: Provide a breakdown of how many times each product was viewed and how many times it was added to the shopping cart.

SELECT
    t1.page_id,
    SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS n_page_views,
    SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS n_added_to_cart
FROM
    shopping_cart_page_hierarchy AS t1
JOIN
    shopping_cart_events AS t2
ON
    t1.page_id = t2.page_id
WHERE
    t1.product_id IS NOT NULL
GROUP BY
    t1.page_id;