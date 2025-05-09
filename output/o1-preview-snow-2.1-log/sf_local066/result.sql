WITH delivered_orders AS (
    SELECT "order_id"
    FROM "MODERN_DATA"."MODERN_DATA"."PIZZA_RUNNER_ORDERS"
    WHERE "cancellation" IS NULL OR "cancellation" = ''
),
customer_delivered_orders AS (
    SELECT c."order_id", c."pizza_id", c."exclusions", c."extras"
    FROM "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" c
    JOIN delivered_orders d ON c."order_id" = d."order_id"
),
order_base_toppings AS (
    SELECT o."order_id", o."pizza_id", TRY_TO_NUMBER(TRIM(value)) AS "topping_id"
    FROM customer_delivered_orders o
    JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_RECIPES" r ON o."pizza_id" = r."pizza_id",
    LATERAL FLATTEN(input => SPLIT(r."toppings", ','))
    WHERE TRY_TO_NUMBER(TRIM(value)) IS NOT NULL
),
order_exclusions AS (
    SELECT o."order_id", TRY_TO_NUMBER(TRIM(value)) AS "exclusion_topping_id"
    FROM customer_delivered_orders o,
    LATERAL FLATTEN(input => SPLIT(o."exclusions", ','))
    WHERE o."exclusions" IS NOT NULL AND TRIM(value) != '' AND TRY_TO_NUMBER(TRIM(value)) IS NOT NULL
),
order_extras AS (
    SELECT o."order_id", TRY_TO_NUMBER(TRIM(value)) AS "extra_topping_id"
    FROM customer_delivered_orders o,
    LATERAL FLATTEN(input => SPLIT(o."extras", ','))
    WHERE o."extras" IS NOT NULL AND TRIM(value) != '' AND TRY_TO_NUMBER(TRIM(value)) IS NOT NULL
),
order_final_toppings AS (
    SELECT b."order_id", b."topping_id"
    FROM order_base_toppings b
    LEFT JOIN order_exclusions e
    ON b."order_id" = e."order_id" AND b."topping_id" = e."exclusion_topping_id"
    WHERE e."exclusion_topping_id" IS NULL
    UNION ALL
    SELECT ex."order_id", ex."extra_topping_id" AS "topping_id"
    FROM order_extras ex
)
SELECT t."topping_name" AS "Name", COUNT(*) AS "Quantity"
FROM order_final_toppings ft
JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_TOPPINGS" t
ON ft."topping_id" = t."topping_id"
GROUP BY t."topping_name"
ORDER BY t."topping_name";