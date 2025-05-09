WITH cte_orders AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY o."order_id", o."pizza_id") AS "row_id",
        o."order_id",
        o."customer_id",
        CASE WHEN p."pizza_name" = 'Meatlovers' THEN 1 ELSE 2 END AS "pizza_id",
        p."pizza_name",
        r."toppings" AS "standard_toppings",
        o."exclusions",
        o."extras"
    FROM 
        "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" o
    JOIN
        "MODERN_DATA"."MODERN_DATA"."PIZZA_NAMES" p
    ON 
        o."pizza_id" = p."pizza_id"
    JOIN
        "MODERN_DATA"."MODERN_DATA"."PIZZA_RECIPES" r
    ON
        o."pizza_id" = r."pizza_id"
),
cte_standard_toppings AS (
    SELECT
        c."row_id",
        TRIM(s.value) AS "topping_id"
    FROM 
        cte_orders c,
        TABLE(FLATTEN(SPLIT(c."standard_toppings", ','))) s
),
cte_exclusions AS (
    SELECT
        c."row_id",
        TRIM(e.value) AS "topping_id"
    FROM 
        cte_orders c,
        TABLE(FLATTEN(SPLIT(c."exclusions", ','))) e
    WHERE c."exclusions" IS NOT NULL AND c."exclusions" <> ''
),
cte_extras AS (
    SELECT
        c."row_id",
        TRIM(e.value) AS "topping_id"
    FROM 
        cte_orders c,
        TABLE(FLATTEN(SPLIT(c."extras", ','))) e
    WHERE c."extras" IS NOT NULL AND c."extras" <> ''
),
cte_standard_toppings_excluded AS (
    SELECT
        st."row_id",
        st."topping_id"
    FROM
        cte_standard_toppings st
    LEFT JOIN
        cte_exclusions ex
    ON
        st."row_id" = ex."row_id" AND st."topping_id" = ex."topping_id"
    WHERE
        ex."topping_id" IS NULL
),
cte_combined_toppings AS (
    SELECT
        "row_id",
        "topping_id"
    FROM
        cte_standard_toppings_excluded
    UNION ALL
    SELECT
        "row_id",
        "topping_id"
    FROM
        cte_extras
),
cte_topping_counts AS (
    SELECT
        "row_id",
        "topping_id",
        COUNT(*) AS "topping_count"
    FROM
        cte_combined_toppings
    GROUP BY
        "row_id",
        "topping_id"
),
cte_topping_names AS (
    SELECT
        tc."row_id",
        CASE WHEN tc."topping_count" > 1 THEN
            CONCAT(tc."topping_count", 'x', t."topping_name")
        ELSE
            t."topping_name"
        END AS "topping_name"
    FROM
        cte_topping_counts tc
    JOIN
        "MODERN_DATA"."MODERN_DATA"."PIZZA_TOPPINGS" t
    ON
        tc."topping_id" = t."topping_id"
),
cte_final_ingredients AS (
    SELECT
        "row_id",
        LISTAGG("topping_name", ', ') WITHIN GROUP (ORDER BY "topping_name") AS "ingredients_list"
    FROM
        cte_topping_names
    GROUP BY
        "row_id"
)
SELECT
    c."row_id",
    c."order_id",
    c."customer_id",
    c."pizza_id",
    c."pizza_name",
    CONCAT(c."pizza_name", ': ', f."ingredients_list") AS "final_ingredients"
FROM
    cte_orders c
LEFT JOIN
    cte_final_ingredients f
ON
    c."row_id" = f."row_id"
ORDER BY
    c."row_id";