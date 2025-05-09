WITH delivered_orders AS (
  SELECT c."order_id", c."pizza_id", c."exclusions", c."extras"
  FROM "pizza_clean_customer_orders" c
  JOIN "pizza_runner_orders" r ON c."order_id" = r."order_id"
  WHERE r."cancellation" IS NULL
),
base_toppings_per_order AS (
  SELECT do."order_id", TRIM(value) AS "topping_id"
  FROM delivered_orders do
  JOIN "pizza_recipes" pr ON do."pizza_id" = pr."pizza_id"
  JOIN json_each('[' || pr."toppings" || ']')
),
exclusions_per_order AS (
  SELECT do."order_id", TRIM(value) AS "topping_id"
  FROM delivered_orders do,
  json_each('[' || do."exclusions" || ']')
  WHERE do."exclusions" IS NOT NULL
),
extras_per_order AS (
  SELECT do."order_id", TRIM(value) AS "topping_id"
  FROM delivered_orders do,
  json_each('[' || do."extras" || ']')
  WHERE do."extras" IS NOT NULL
),
adjusted_base_toppings_per_order AS (
  SELECT bto."order_id", bto."topping_id"
  FROM base_toppings_per_order bto
  LEFT JOIN exclusions_per_order epo ON bto."order_id" = epo."order_id" AND bto."topping_id" = epo."topping_id"
  WHERE epo."topping_id" IS NULL
),
adjusted_toppings_per_order AS (
  SELECT "order_id", "topping_id" FROM adjusted_base_toppings_per_order
  UNION ALL
  SELECT "order_id", "topping_id" FROM extras_per_order
),
toppings_usage AS (
  SELECT "topping_id", COUNT(*) AS "Total_Quantity"
  FROM adjusted_toppings_per_order
  GROUP BY "topping_id"
)
SELECT pt."topping_name" AS "Ingredient_Name", tu."Total_Quantity"
FROM toppings_usage tu
JOIN "pizza_toppings" pt ON tu."topping_id" = pt."topping_id"
ORDER BY "Ingredient_Name";