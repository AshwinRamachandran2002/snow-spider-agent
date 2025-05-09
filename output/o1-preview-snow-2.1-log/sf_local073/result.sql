WITH orders AS (
    SELECT
        o."order_id",
        ROW_NUMBER() OVER (PARTITION BY o."order_id" ORDER BY o."pizza_id", o."order_time") AS "order_item_id",
        o."pizza_id",
        n."pizza_name",
        o."exclusions",
        o."extras"
    FROM "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" o
    JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_NAMES" n
        ON o."pizza_id" = n."pizza_id"
),
default_toppings AS (
    SELECT
        o."order_id",
        o."order_item_id",
        o."pizza_name",
        SPLIT(TRIM(REPLACE(r."toppings", ' ', '')), ',') AS "topping_ids"
    FROM orders o
    JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_RECIPES" r
        ON o."pizza_id" = r."pizza_id"
),
default_toppings_expanded AS (
    SELECT
        dt."order_id",
        dt."order_item_id",
        dt."pizza_name",
        CAST(tid.VALUE AS INT) AS "topping_id",
        1 AS "count"
    FROM default_toppings dt,
    LATERAL FLATTEN(input => dt."topping_ids") tid
    WHERE tid.VALUE IS NOT NULL AND tid.VALUE != ''
),
exclusions AS (
    SELECT
        o."order_id",
        o."order_item_id",
        SPLIT(TRIM(REPLACE(o."exclusions", ' ', '')), ',') AS "exclusion_ids"
    FROM orders o
    WHERE o."exclusions" IS NOT NULL AND o."exclusions" != ''
),
exclusions_exploded AS (
    SELECT
        e."order_id",
        e."order_item_id",
        CAST(eid.VALUE AS INT) AS "topping_id"
    FROM exclusions e,
    LATERAL FLATTEN(input => e."exclusion_ids") eid
    WHERE eid.VALUE IS NOT NULL AND eid.VALUE != ''
),
toppings_after_exclusions AS (
    SELECT
        dte."order_id",
        dte."order_item_id",
        dte."pizza_name",
        dte."topping_id",
        dte."count"
    FROM default_toppings_expanded dte
    LEFT JOIN exclusions_exploded ee
        ON dte."order_id" = ee."order_id"
        AND dte."order_item_id" = ee."order_item_id"
        AND dte."topping_id" = ee."topping_id"
    WHERE ee."topping_id" IS NULL
),
extras AS (
    SELECT
        o."order_id",
        o."order_item_id",
        SPLIT(TRIM(REPLACE(o."extras", ' ', '')), ',') AS "extra_ids"
    FROM orders o
    WHERE o."extras" IS NOT NULL AND o."extras" != ''
),
extras_exploded AS (
    SELECT
        e."order_id",
        e."order_item_id",
        CAST(eid.VALUE AS INT) AS "topping_id",
        1 AS "count"
    FROM extras e,
    LATERAL FLATTEN(input => e."extra_ids") eid
    WHERE eid.VALUE IS NOT NULL AND eid.VALUE != ''
),
all_toppings AS (
    SELECT
        tae."order_id",
        tae."order_item_id",
        tae."pizza_name",
        tae."topping_id",
        tae."count"
    FROM toppings_after_exclusions tae
    UNION ALL
    SELECT
        ee."order_id",
        ee."order_item_id",
        o."pizza_name",
        ee."topping_id",
        ee."count"
    FROM extras_exploded ee
    JOIN orders o
        ON ee."order_id" = o."order_id"
        AND ee."order_item_id" = o."order_item_id"
),
topping_counts AS (
    SELECT
        at."order_id",
        at."order_item_id",
        at."pizza_name",
        at."topping_id",
        SUM(at."count") AS "count"
    FROM all_toppings at
    GROUP BY at."order_id", at."order_item_id", at."pizza_name", at."topping_id"
),
toppings_with_names AS (
    SELECT
        tc."order_id",
        tc."order_item_id",
        tc."pizza_name",
        t."topping_name",
        tc."count"
    FROM topping_counts tc
    JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_TOPPINGS" t
        ON tc."topping_id" = t."topping_id"
)
SELECT
    twn."order_id",
    twn."pizza_name" || ': ' || LISTAGG(
        CASE
            WHEN twn."count" > 1 THEN TO_VARCHAR(twn."count") || 'x' || twn."topping_name"
            ELSE twn."topping_name"
        END,
        ', '
    ) WITHIN GROUP (ORDER BY twn."topping_name") AS "Pizza_Details"
FROM toppings_with_names twn
GROUP BY twn."order_id", twn."order_item_id", twn."pizza_name"
ORDER BY twn."order_id", twn."order_item_id";