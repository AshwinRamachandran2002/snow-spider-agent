WITH
    -- Split the default toppings from recipes
    recipe_toppings AS (
        SELECT pr."pizza_id",
               TRIM(SUBSTR(pr."toppings" || ',', 1, INSTR(pr."toppings" || ',', ',') - 1)) AS "topping_id",
               SUBSTR(pr."toppings" || ',', INSTR(pr."toppings" || ',', ',') + 1) AS "rest"
        FROM "pizza_recipes" pr
        UNION ALL
        SELECT rt."pizza_id",
               TRIM(SUBSTR(rt."rest", 1, INSTR(rt."rest", ',') - 1)) AS "topping_id",
               SUBSTR(rt."rest", INSTR(rt."rest", ',') + 1) AS "rest"
        FROM recipe_toppings rt
        WHERE rt."rest" <> ''
    ),
    
    -- Get the default toppings per order
    order_default_toppings AS (
        SELECT o."order_id", pn."pizza_name", rt."topping_id"
        FROM "pizza_customer_orders" o
        JOIN "pizza_names" pn ON o."pizza_id" = pn."pizza_id"
        JOIN recipe_toppings rt ON o."pizza_id" = rt."pizza_id"
    ),
    
    -- Split the exclusions
    order_exclusions AS (
        SELECT o."order_id",
               TRIM(SUBSTR(o."exclusions" || ',', 1, INSTR(o."exclusions" || ',', ',') - 1)) AS "topping_id",
               SUBSTR(o."exclusions" || ',', INSTR(o."exclusions" || ',', ',') + 1) AS "rest"
        FROM "pizza_customer_orders" o
        WHERE o."exclusions" IS NOT NULL AND o."exclusions" <> ''
        UNION ALL
        SELECT oe."order_id",
               TRIM(SUBSTR(oe."rest", 1, INSTR(oe."rest", ',') - 1)) AS "topping_id",
               SUBSTR(oe."rest", INSTR(oe."rest", ',') + 1) AS "rest"
        FROM order_exclusions oe
        WHERE oe."rest" <> ''
    ),
    
    -- Split the extras
    order_extras AS (
        SELECT o."order_id",
               TRIM(SUBSTR(o."extras" || ',', 1, INSTR(o."extras" || ',', ',') - 1)) AS "topping_id",
               SUBSTR(o."extras" || ',', INSTR(o."extras" || ',', ',') + 1) AS "rest"
        FROM "pizza_customer_orders" o
        WHERE o."extras" IS NOT NULL AND o."extras" <> ''
        UNION ALL
        SELECT oe."order_id",
               TRIM(SUBSTR(oe."rest", 1, INSTR(oe."rest", ',') - 1)) AS "topping_id",
               SUBSTR(oe."rest", INSTR(oe."rest", ',') + 1) AS "rest"
        FROM order_extras oe
        WHERE oe."rest" <> ''
    ),
    
    -- Calculate the final toppings per order
    final_toppings AS (
        -- Start with default toppings and exclude any exclusions
        SELECT dt."order_id", dt."pizza_name", dt."topping_id"
        FROM order_default_toppings dt
        LEFT JOIN order_exclusions oe ON dt."order_id" = oe."order_id" AND dt."topping_id" = oe."topping_id"
        WHERE oe."topping_id" IS NULL
        UNION ALL
        -- Add any extras
        SELECT oe."order_id", NULL AS "pizza_name", oe."topping_id"
        FROM order_extras oe
    ),
    
    -- Count the occurrences of each topping per order
    topping_counts AS (
        SELECT "order_id", "topping_id", COUNT(*) AS "count"
        FROM final_toppings
        GROUP BY "order_id", "topping_id"
    ),
    
    -- Map topping IDs to names and handle duplicates
    ingredients_list AS (
        SELECT tc."order_id",
               (CASE WHEN tc."count" > 1 THEN '2x' || pt."topping_name" ELSE pt."topping_name" END) AS "topping_name"
        FROM topping_counts tc
        JOIN "pizza_toppings" pt ON tc."topping_id" = pt."topping_id"
    ),
    
    -- Order the ingredients alphabetically per order
    ordered_ingredients AS (
        SELECT il."order_id",
               il."topping_name"
        FROM ingredients_list il
        ORDER BY il."order_id", il."topping_name"
    ),
    
    -- Concatenate the ingredients per order
    ingredients_per_order AS (
        SELECT "order_id",
               GROUP_CONCAT("topping_name", ', ') AS "Ingredients"
        FROM ordered_ingredients
        GROUP BY "order_id"
    )
    
SELECT o."order_id" AS "Order_ID",
       MAX(o."pizza_name") AS "Pizza_Name",
       ipo."Ingredients"
FROM order_default_toppings o
JOIN ingredients_per_order ipo ON o."order_id" = ipo."order_id"
GROUP BY o."order_id"
ORDER BY o."order_id";