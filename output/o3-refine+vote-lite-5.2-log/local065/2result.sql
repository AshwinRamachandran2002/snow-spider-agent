WITH base_prices AS (
    -- Price list for the only two pizzas we are asked about
    SELECT
        pizza_id,
        CASE
            WHEN LOWER(pizza_name) = 'meatlovers'  THEN 12   -- Meat Lovers
            WHEN LOWER(pizza_name) = 'vegetarian'  THEN 10   -- Vegetarian
        END AS base_price
    FROM pizza_names
    WHERE LOWER(pizza_name) IN ('meatlovers', 'vegetarian')
),
valid_orders AS (
    -- Keep only orders that were actually delivered (i.e., not cancelled)
    SELECT
        c.order_id,
        c.pizza_id
    FROM pizza_clean_customer_orders  AS c
    JOIN pizza_clean_runner_orders    AS r
          ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL
),
extras_per_order AS (
    -- Total number of extra toppings on each order
    SELECT
        order_id,
        COALESCE(SUM(extras_count),0) AS extras_cnt
    FROM pizza_get_extras
    GROUP BY order_id
)
SELECT
    SUM(bp.base_price + e.extras_cnt * 1) AS total_income
FROM valid_orders         AS v
JOIN base_prices          AS bp ON v.pizza_id = bp.pizza_id
LEFT JOIN extras_per_order AS e ON v.order_id = e.order_id;