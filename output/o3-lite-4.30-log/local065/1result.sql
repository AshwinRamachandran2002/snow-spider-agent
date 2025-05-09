WITH delivered AS (
    SELECT order_id
    FROM pizza_clean_runner_orders
    WHERE cancellation IS NULL OR cancellation = ''
),
base_totals AS (
    SELECT 
        order_id,
        SUM(CASE pizza_id 
                WHEN 1 THEN 12      -- Meat Lovers
                WHEN 2 THEN 10      -- Vegetarian
            END) AS base_total
    FROM pizza_clean_customer_orders
    WHERE pizza_id IN (1,2)
      AND order_id IN (SELECT order_id FROM delivered)
    GROUP BY order_id
),
extras_totals AS (
    SELECT 
        order_id,
        SUM(extras_count) AS extras_total
    FROM pizza_get_extras
    GROUP BY order_id
)
SELECT 
    printf('%.4f', SUM(base_total + COALESCE(extras_total,0))) AS total_income
FROM base_totals
LEFT JOIN extras_totals USING (order_id);