WITH delivered_pizzas AS (
    SELECT
        o.order_id,
        CASE n.pizza_name
            WHEN 'Meatlovers' THEN 12          -- base price
            WHEN 'Vegetarian' THEN 10
        END AS base_price
    FROM pizza_clean_customer_orders AS o
    JOIN pizza_names               AS n ON n.pizza_id = o.pizza_id
    JOIN pizza_clean_runner_orders AS r ON r.order_id = o.order_id
    WHERE r.cancellation IS NULL                    -- exclude cancelled orders
),
extras_per_order AS (
    SELECT
        order_id,
        SUM(extras_count) AS extra_dollars          -- $1 per extra topping
    FROM pizza_get_extras
    GROUP BY order_id
)
SELECT
    SUM(dp.base_price + COALESCE(ep.extra_dollars, 0)) AS total_income
FROM delivered_pizzas dp
LEFT JOIN extras_per_order ep USING (order_id);