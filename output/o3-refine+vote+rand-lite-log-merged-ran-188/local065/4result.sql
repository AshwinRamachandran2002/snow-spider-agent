WITH delivered_orders AS (
    /* keep only orders that were actually delivered and are either Meat Lovers or Vegetarian */
    SELECT c.order_id,
           c.pizza_id
    FROM pizza_clean_customer_orders   AS c
    JOIN pizza_clean_runner_orders     AS r
          ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL            -- not cancelled
      AND c.pizza_id IN (1,2)               -- 1 = Meat Lovers, 2 = Vegetarian
),
extras_per_order AS (
    /* total count of extra toppings for each order (every extra costs $1) */
    SELECT order_id,
           COALESCE(SUM(extras_count),0) AS total_extras
    FROM pizza_get_extras
    GROUP BY order_id
)
SELECT
    SUM(
        /* base pizza price */
        CASE d.pizza_id
            WHEN 1 THEN 12     -- Meat Lovers
            WHEN 2 THEN 10     -- Vegetarian
        END
        /* add $1 for each extra topping */
        + COALESCE(e.total_extras,0) * 1
    ) AS total_income
FROM delivered_orders d
LEFT JOIN extras_per_order e
       ON d.order_id = e.order_id;