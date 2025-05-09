WITH delivered_orders AS (
    SELECT
        c."order_id",
        c."pizza_id",
        c."exclusions",
        c."extras"
    FROM
        "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" c
    JOIN
        "MODERN_DATA"."MODERN_DATA"."PIZZA_RUNNER_ORDERS" r
        ON c."order_id" = r."order_id"
    WHERE
        r."cancellation" IS NULL
        OR r."cancellation" = ''
),
order_toppings AS (
    SELECT
        o."order_id",
        SPLIT(TRIM(REGEXP_REPLACE(p."toppings", '\\s+', '')), ',') AS base_toppings_array,
        CASE
            WHEN o."exclusions" IS NULL OR TRIM(o."exclusions") = ''
            THEN ARRAY_CONSTRUCT()
            ELSE SPLIT(TRIM(REGEXP_REPLACE(o."exclusions", '\\s+', '')), ',')
        END AS exclusions_array,
        CASE
            WHEN o."extras" IS NULL OR TRIM(o."extras") = ''
            THEN ARRAY_CONSTRUCT()
            ELSE SPLIT(TRIM(REGEXP_REPLACE(o."extras", '\\s+', '')), ',')
        END AS extras_array
    FROM
        delivered_orders o
    JOIN
        "MODERN_DATA"."MODERN_DATA"."PIZZA_RECIPES" p
        ON o."pizza_id" = p."pizza_id"
),
toppings_per_order AS (
    -- Base toppings minus exclusions
    SELECT
        o."order_id",
        bt.value::VARCHAR AS topping_id_str
    FROM
        order_toppings o,
        TABLE(FLATTEN(input => o.base_toppings_array)) bt
    WHERE
        bt.value IS NOT NULL
        AND TRIM(bt.value) != ''
        AND (
            o.exclusions_array IS NULL
            OR ARRAY_SIZE(o.exclusions_array) = 0
            OR NOT ARRAY_CONTAINS(o.exclusions_array, bt.value)
        )
    UNION ALL
    -- Add extras
    SELECT
        o."order_id",
        extr.value::VARCHAR AS topping_id_str
    FROM
        order_toppings o,
        TABLE(FLATTEN(input => o.extras_array)) extr
    WHERE
        extr.value IS NOT NULL
        AND TRIM(extr.value) != ''
)
SELECT
    t."topping_name" AS "Name",
    COUNT(*) AS "Quantity"
FROM
    toppings_per_order tp
JOIN
    "MODERN_DATA"."MODERN_DATA"."PIZZA_TOPPINGS" t
    ON tp.topping_id_str = t."topping_id"::VARCHAR
GROUP BY
    t."topping_name"
ORDER BY
    "Quantity" DESC NULLS LAST
LIMIT 100;