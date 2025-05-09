WITH
order_details AS (
    SELECT
        pco."order_id",
        pco."pizza_id",
        pn."pizza_name",
        pr."toppings" AS "standard_toppings",
        pco."exclusions",
        pco."extras"
    FROM "pizza_customer_orders" pco
    JOIN "pizza_recipes" pr ON pco."pizza_id" = pr."pizza_id"
    JOIN "pizza_names" pn ON pco."pizza_id" = pn."pizza_id"
),
standard_toppings_split(order_id, pizza_id, pizza_name, topping_id, rest) AS (
    SELECT 
        "order_id", 
        "pizza_id", 
        "pizza_name",
        NULLIF(TRIM(SUBSTR("standard_toppings" || ',', 1, INSTR("standard_toppings" || ',', ',') -1)), '') AS "topping_id",
        TRIM(SUBSTR("standard_toppings" || ',', INSTR("standard_toppings" || ',', ',') +1)) AS rest
    FROM order_details
    WHERE "standard_toppings" IS NOT NULL AND "standard_toppings" <> ''
    UNION ALL
    SELECT 
        "order_id", 
        "pizza_id", 
        "pizza_name",
        NULLIF(TRIM(SUBSTR(rest, 1, INSTR(rest, ',') -1)), '') AS "topping_id",
        TRIM(SUBSTR(rest, INSTR(rest, ',') +1)) AS rest
    FROM standard_toppings_split
    WHERE rest LIKE '%,%'
),
exclusions_split(order_id, topping_id, rest) AS (
    SELECT 
        "order_id", 
        NULLIF(TRIM(SUBSTR("exclusions" || ',', 1, INSTR("exclusions" || ',', ',') -1)), '') AS "topping_id",
        TRIM(SUBSTR("exclusions" || ',', INSTR("exclusions" || ',', ',') +1)) AS rest
    FROM order_details
    WHERE "exclusions" IS NOT NULL AND "exclusions" <> ''
    UNION ALL
    SELECT
        "order_id",
        NULLIF(TRIM(SUBSTR(rest, 1, INSTR(rest, ',') -1)), '') AS "topping_id",
        TRIM(SUBSTR(rest, INSTR(rest, ',') +1)) AS rest
    FROM exclusions_split
    WHERE rest LIKE '%,%'
),
extras_split(order_id, topping_id, rest) AS (
    SELECT 
        "order_id",
        NULLIF(TRIM(SUBSTR("extras" || ',', 1, INSTR("extras" || ',', ',') -1)), '') AS "topping_id",
        TRIM(SUBSTR("extras" || ',', INSTR("extras" || ',', ',') +1)) AS rest
    FROM order_details
    WHERE "extras" IS NOT NULL AND "extras" <> ''
    UNION ALL
    SELECT
        "order_id",
        NULLIF(TRIM(SUBSTR(rest, 1, INSTR(rest, ',') -1)), '') AS "topping_id",
        TRIM(SUBSTR(rest, INSTR(rest, ',') +1)) AS rest
    FROM extras_split
    WHERE rest LIKE '%,%'
),
order_toppings AS (
    SELECT
        "order_id",
        "pizza_id",
        "pizza_name",
        "topping_id",
        1 AS quantity
    FROM standard_toppings_split
    WHERE "topping_id" IS NOT NULL
),
order_toppings_without_exclusions AS (
    SELECT ot.*
    FROM order_toppings ot
    LEFT JOIN exclusions_split ex ON ot."order_id" = ex."order_id" AND ot."topping_id" = ex."topping_id"
    WHERE ex."topping_id" IS NULL
),
order_toppings_with_extras AS (
    SELECT 
        otwe."order_id",
        otwe."pizza_id",
        otwe."pizza_name",
        otwe."topping_id",
        otwe.quantity
    FROM order_toppings_without_exclusions otwe
    UNION ALL
    SELECT
        "order_id",
        NULL AS "pizza_id",
        NULL AS "pizza_name",
        "topping_id",
        1 AS quantity
    FROM extras_split
    WHERE "topping_id" IS NOT NULL
),
order_toppings_aggregated AS (
    SELECT
        "order_id",
        "topping_id",
        SUM(quantity) AS quantity
    FROM order_toppings_with_extras
    GROUP BY "order_id", "topping_id"
),
order_toppings_with_names AS (
    SELECT
        ota."order_id",
        ota."topping_id",
        ota.quantity,
        pt."topping_name"
    FROM order_toppings_aggregated ota
    JOIN "pizza_toppings" pt ON ota."topping_id" = pt."topping_id"
)
SELECT
    od."order_id" AS "Order_ID",
    od."pizza_name" AS "Pizza_Name",
    (SELECT GROUP_CONCAT(
        CASE WHEN otn2.quantity > 1 THEN otn2.quantity || 'x' || otn2."topping_name" ELSE otn2."topping_name" END,
        ';'
    )
    FROM (
        SELECT otn."topping_name", otn.quantity
        FROM order_toppings_with_names otn
        WHERE otn."order_id" = od."order_id"
        ORDER BY otn."topping_name"
    ) otn2
    ) AS "Ingredients"
FROM order_details od
GROUP BY od."order_id", od."pizza_name"
ORDER BY od."order_id";