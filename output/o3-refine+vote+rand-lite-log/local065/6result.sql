WITH delivered AS (
    -- orders that were actually delivered (i.e. not cancelled)
    SELECT c.order_id,
           c.pizza_id
    FROM pizza_customer_orders  AS c
    JOIN pizza_runner_orders    AS r
          ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL
),
extras AS (
    -- total number of extra toppings per order
    SELECT order_id,
           SUM(COALESCE(extras_count,0)) AS extra_cnt
    FROM pizza_get_extras
    GROUP BY order_id
)
SELECT
    SUM(
        CASE delivered.pizza_id               -- base price
             WHEN 1 THEN 12                   -- Meat Lovers
             WHEN 2 THEN 10                   -- Vegetarian
        END
        +
        COALESCE(extras.extra_cnt,0)          -- $1 per extra topping
    ) AS total_income
FROM delivered
LEFT JOIN extras
       ON delivered.order_id = extras.order_id
WHERE delivered.pizza_id IN (1,2);