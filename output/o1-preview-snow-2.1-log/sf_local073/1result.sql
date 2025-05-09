WITH customer_orders AS (
    SELECT 
        o."order_id",
        o."pizza_id",
        p."pizza_name",
        o."exclusions",
        o."extras"
    FROM "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" o
    JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_NAMES" p
      ON o."pizza_id" = p."pizza_id"
),
default_toppings AS (
    SELECT
        r."pizza_id",
        TRY_TO_NUMBER(TRIM(t.value)) AS "topping_id"
    FROM "MODERN_DATA"."MODERN_DATA"."PIZZA_RECIPES" r,
    LATERAL FLATTEN(input => SPLIT(r."toppings", ',')) t
    WHERE TRY_TO_NUMBER(TRIM(t.value)) IS NOT NULL
),
exclusions AS (
    SELECT
        o."order_id",
        TRY_TO_NUMBER(TRIM(e.value)) AS "topping_id"
    FROM customer_orders o,
    LATERAL FLATTEN(input => SPLIT(o."exclusions", ',')) e
    WHERE o."exclusions" IS NOT NULL AND TRY_TO_NUMBER(TRIM(e.value)) IS NOT NULL
),
extras AS (
    SELECT
        o."order_id",
        TRY_TO_NUMBER(TRIM(e.value)) AS "topping_id"
    FROM customer_orders o,
    LATERAL FLATTEN(input => SPLIT(o."extras", ',')) e
    WHERE o."extras" IS NOT NULL AND TRY_TO_NUMBER(TRIM(e.value)) IS NOT NULL
),
order_toppings AS (
    -- Default toppings after exclusions
    SELECT
        o."order_id",
        dt."topping_id",
        1 AS "topping_count"
    FROM customer_orders o
    JOIN default_toppings dt
        ON o."pizza_id" = dt."pizza_id"
    LEFT JOIN exclusions ex
        ON o."order_id" = ex."order_id" AND dt."topping_id" = ex."topping_id"
    WHERE ex."topping_id" IS NULL
    UNION ALL
    -- Extras
    SELECT
        o."order_id",
        exr."topping_id",
        1 AS "topping_count"
    FROM customer_orders o
    JOIN extras exr
        ON o."order_id" = exr."order_id"
),
toppings_with_counts AS (
    SELECT
        ot."order_id",
        ot."topping_id",
        SUM(ot."topping_count") AS "topping_count"
    FROM order_toppings ot
    GROUP BY ot."order_id", ot."topping_id"
),
toppings_with_names AS (
    SELECT
        tc."order_id",
        tc."topping_id",
        tc."topping_count",
        tp."topping_name"
    FROM toppings_with_counts tc
    JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_TOPPINGS" tp
        ON tc."topping_id" = tp."topping_id"
),
ingredients_list AS (
    SELECT
        twc."order_id",
        CASE WHEN twc."topping_count" > 1 
             THEN CONCAT(twc."topping_count", 'x', twc."topping_name")
             ELSE twc."topping_name" END AS "ingredient"
    FROM toppings_with_names twc
),
final_report AS (
    SELECT
        co."order_id",
        co."pizza_name",
        LISTAGG(il."ingredient", ', ') WITHIN GROUP (ORDER BY il."ingredient") AS "ingredients"
    FROM customer_orders co
    JOIN ingredients_list il
        ON co."order_id" = il."order_id"
    GROUP BY co."order_id", co."pizza_name"
)
SELECT
    fr."order_id",
    CONCAT(fr."pizza_name", ': ', fr."ingredients") AS "Pizza_Details"
FROM final_report fr
ORDER BY fr."order_id";