-- Task: List all the base toppings used in each pizza recipe.
WITH split_regular_toppings AS (
    SELECT
        pizza_id,
        TRIM(SUBSTR(toppings, 1, INSTR(toppings || ',', ',') - 1)) AS topping_id,
        SUBSTR(toppings || ',', INSTR(toppings || ',', ',') + 1) AS remaining_toppings
    FROM 
        pizza_recipes
    UNION ALL
    SELECT
        pizza_id,
        TRIM(SUBSTR(remaining_toppings, 1, INSTR(remaining_toppings, ',') - 1)) AS topping_id,
        SUBSTR(remaining_toppings, INSTR(remaining_toppings, ',') + 1) AS remaining_toppings
    FROM 
        split_regular_toppings
    WHERE
        remaining_toppings <> ''
)
SELECT
    pizza_id,
    topping_id
FROM 
    split_regular_toppings;