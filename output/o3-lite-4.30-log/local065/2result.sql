WITH delivered AS (
  SELECT order_id
  FROM pizza_clean_runner_orders
  WHERE cancellation IS NULL
),
base_total AS (
  SELECT SUM(
           CASE
             WHEN cco.pizza_id = 1 THEN 12
             WHEN cco.pizza_id = 2 THEN 10
           END
         ) AS amount
  FROM pizza_clean_customer_orders AS cco
  WHERE cco.order_id IN (SELECT order_id FROM delivered)
    AND cco.pizza_id IN (1,2)
),
extras_total AS (
  SELECT COALESCE(SUM(ge.extras_count),0) AS amount
  FROM pizza_get_extras AS ge
  WHERE ge.order_id IN (SELECT order_id FROM delivered)
)
SELECT printf('%.4f',
              (SELECT amount FROM base_total) +
              (SELECT amount FROM extras_total)
       ) AS total_income;