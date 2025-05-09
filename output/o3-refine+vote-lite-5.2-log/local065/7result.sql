WITH delivered_orders AS (
    SELECT c.order_id,
           c.pizza_id
    FROM pizza_clean_customer_orders AS c
    JOIN pizza_clean_runner_orders AS r
      ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL                      -- exclude cancelled orders
),
extras_per_order AS (
    SELECT order_id,
           SUM(COALESCE(extras_count,0)) AS extra_cnt -- total extras per order
    FROM pizza_get_extras
    GROUP BY order_id
)
SELECT
    SUM(                                            -- base pizza price
        CASE delivered_orders.pizza_id
             WHEN 1 THEN 12      -- Meat Lovers
             WHEN 2 THEN 10      -- Vegetarian
        END
        + COALESCE(extras_per_order.extra_cnt,0)    -- plus $1 per extra topping
    ) AS total_income
FROM delivered_orders
LEFT JOIN extras_per_order
  ON delivered_orders.order_id = extras_per_order.order_id;