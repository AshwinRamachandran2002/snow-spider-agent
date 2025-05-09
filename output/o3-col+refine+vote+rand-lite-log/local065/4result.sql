WITH delivered_orders AS (
    SELECT DISTINCT order_id
    FROM pizza_clean_runner_orders
    WHERE cancellation IS NULL
),
pizza_revenue AS (
    SELECT SUM(
             CASE pn.pizza_name
                  WHEN 'Meatlovers'  THEN 12
                  WHEN 'Vegetarian' THEN 10
                  ELSE 0
             END
           ) AS amt
    FROM pizza_customer_orders AS cco
    JOIN delivered_orders       AS d  ON cco.order_id = d.order_id
    JOIN pizza_names            AS pn ON cco.pizza_id = pn.pizza_id
),
extras_revenue AS (
    SELECT COALESCE(SUM(ge.extras_count),0) AS amt
    FROM   pizza_get_extras  AS ge
    JOIN   delivered_orders  AS d  ON ge.order_id = d.order_id
)
SELECT pizza_revenue.amt + extras_revenue.amt AS total_income
FROM   pizza_revenue
CROSS  JOIN extras_revenue;