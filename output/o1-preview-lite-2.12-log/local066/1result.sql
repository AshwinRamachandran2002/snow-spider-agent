WITH RECURSIVE
delivered_orders AS (
    SELECT pc.order_id, pc.pizza_id, pc.exclusions, pc.extras, r.toppings AS base_toppings
    FROM "pizza_customer_orders" pc
    JOIN "pizza_runner_orders" pr ON pc.order_id = pr.order_id
    JOIN "pizza_recipes" r ON pc.pizza_id = r.pizza_id
    WHERE pr.cancellation IS NULL
),
split_base_toppings(order_id, topping_id, rest) AS (
    SELECT order_id,
           TRIM(SUBSTR(base_toppings, 1, INSTR(base_toppings || ',', ',') - 1)) AS topping_id,
           SUBSTR(base_toppings || ',', INSTR(base_toppings || ',', ',') + 1) AS rest
    FROM delivered_orders
    UNION ALL
    SELECT order_id,
           TRIM(SUBSTR(rest, 1, INSTR(rest, ',') - 1)) AS topping_id,
           SUBSTR(rest, INSTR(rest, ',') + 1)
    FROM split_base_toppings
    WHERE rest <> ''
),
split_exclusions(order_id, topping_id, rest) AS (
    SELECT order_id,
           TRIM(SUBSTR(exclusions, 1, INSTR(exclusions || ',', ',') - 1)),
           SUBSTR(exclusions || ',', INSTR(exclusions || ',', ',') + 1)
    FROM delivered_orders
    WHERE exclusions IS NOT NULL AND exclusions != ''
    UNION ALL
    SELECT order_id,
           TRIM(SUBSTR(rest, 1, INSTR(rest, ',') - 1)),
           SUBSTR(rest, INSTR(rest, ',') + 1)
    FROM split_exclusions
    WHERE rest <> ''
),
split_extras(order_id, topping_id, rest) AS (
    SELECT order_id,
           TRIM(SUBSTR(extras, 1, INSTR(extras || ',', ',') - 1)),
           SUBSTR(extras || ',', INSTR(extras || ',', ',') + 1)
    FROM delivered_orders
    WHERE extras IS NOT NULL AND extras != ''
    UNION ALL
    SELECT order_id,
           TRIM(SUBSTR(rest, 1, INSTR(rest, ',') - 1)),
           SUBSTR(rest, INSTR(rest, ',') + 1)
    FROM split_extras
    WHERE rest <> ''
),
final_toppings AS (
    -- Base toppings minus exclusions
    SELECT sbt.order_id, sbt.topping_id
    FROM split_base_toppings sbt
    LEFT JOIN split_exclusions se ON sbt.order_id = se.order_id AND sbt.topping_id = se.topping_id
    WHERE se.topping_id IS NULL
    UNION ALL
    -- Add extras
    SELECT se.order_id, se.topping_id
    FROM split_extras se
)
SELECT t.topping_name AS Ingredient_Name, COUNT(*) AS Total_Quantity
FROM final_toppings ft
JOIN "pizza_toppings" t ON ft.topping_id = t.topping_id
GROUP BY t.topping_name
ORDER BY Total_Quantity DESC;