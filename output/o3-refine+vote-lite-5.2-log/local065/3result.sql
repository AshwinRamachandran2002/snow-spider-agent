WITH delivered_orders AS (
    -- keep only orders that were actually delivered (not cancelled)
    SELECT  c.order_id,
            c.pizza_id,
            COALESCE(e.total_extras,0)  AS extras_cnt
    FROM    pizza_clean_customer_orders AS c
    JOIN    pizza_clean_runner_orders   AS r
           ON r.order_id = c.order_id
    LEFT JOIN (
        -- total number of extra toppings for each order
        SELECT  order_id,
                SUM(extras_count) AS total_extras
        FROM    pizza_get_extras
        GROUP BY order_id
    ) AS e
           ON e.order_id = c.order_id
    WHERE   r.cancellation IS NULL          -- filter out cancelled jobs
),
price_map AS (
    -- base prices for the two pizzas we are asked about
    SELECT  pizza_id,
            CASE pizza_name
                 WHEN 'Meatlovers' THEN 12   -- $12 each
                 WHEN 'Vegetarian' THEN 10   -- $10 each
            END AS base_price
    FROM    pizza_names
    WHERE   pizza_name IN ('Meatlovers','Vegetarian')
)
SELECT  SUM(p.base_price + d.extras_cnt) AS total_income
FROM    delivered_orders d
JOIN    price_map       p  ON p.pizza_id = d.pizza_id;