WITH Delivered_Orders AS (
  SELECT order_id
  FROM pizza_runner_orders
  WHERE cancellation IS NULL OR cancellation = ''
),
Orders AS (
  SELECT o.*
  FROM pizza_customer_orders o
  JOIN Delivered_Orders d ON o.order_id = d.order_id
),
Default_Toppings AS (
  SELECT
    o.order_id,
    CAST(value AS INTEGER) AS topping_id
  FROM
    Orders o
    JOIN pizza_recipes r ON o.pizza_id = r.pizza_id,
    json_each('[' || REPLACE(r.toppings, ' ', '') || ']')
),
Exclusions AS (
  SELECT
    o.order_id,
    CAST(value AS INTEGER) AS topping_id
  FROM
    Orders o,
    json_each('[' || REPLACE(o.exclusions, ' ', '') || ']')
  WHERE o.exclusions IS NOT NULL AND o.exclusions != ''
),
Extras AS (
  SELECT
    o.order_id,
    CAST(value AS INTEGER) AS topping_id
  FROM
    Orders o,
    json_each('[' || REPLACE(o.extras, ' ', '') || ']')
  WHERE o.extras IS NOT NULL AND o.extras != ''
),
Final_Toppings AS (
  SELECT
    dt.order_id,
    dt.topping_id
  FROM
    Default_Toppings dt
    LEFT JOIN Exclusions e ON dt.order_id = e.order_id AND dt.topping_id = e.topping_id
  WHERE
    e.topping_id IS NULL
  UNION ALL
  SELECT
    order_id,
    topping_id
  FROM
    Extras
)
SELECT
  t.topping_name AS Ingredient_Name,
  COUNT(*) AS Total_Quantity
FROM
  Final_Toppings ft
  JOIN pizza_toppings t ON ft.topping_id = t.topping_id
GROUP BY
  t.topping_name
ORDER BY
  Total_Quantity DESC,
  t.topping_name;