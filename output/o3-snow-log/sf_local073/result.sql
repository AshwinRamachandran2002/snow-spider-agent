WITH orders AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY "order_id")               AS row_id,
        "order_id",
        "customer_id",
        CASE WHEN "pizza_id" = 1 THEN 1 ELSE 2 END            AS pizza_id,
        "exclusions",
        "extras",
        "order_time"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS
),

/* ------------------------------------------------------------ */
/* 1.  Standard recipe toppings                                 */
/* ------------------------------------------------------------ */
recipe_toppings AS (
    SELECT
        o.row_id,
        TRIM(rt.value)::NUMBER                                AS topping_id,
        1                                                     AS qty
    FROM orders o
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_RECIPES r
          ON r."pizza_id" = o.pizza_id
    , LATERAL FLATTEN(INPUT => SPLIT(r."toppings", ',')) rt
),

/* ------------------------------------------------------------ */
/* 2.  Extra toppings (additions)                               */
/* ------------------------------------------------------------ */
extra_toppings AS (
    SELECT
        o.row_id,
        TRIM(et.value)::NUMBER                                AS topping_id,
        1                                                     AS qty
    FROM orders o
    , LATERAL FLATTEN(INPUT => SPLIT(NULLIF(o."extras", ''), ',')) et
    WHERE TRIM(et.value) IS NOT NULL
),

/* ------------------------------------------------------------ */
/* 3.  Excluded toppings (removals)                             */
/* ------------------------------------------------------------ */
exclusion_toppings AS (
    SELECT
        o.row_id,
        TRIM(xt.value)::NUMBER                                AS topping_id,
       -1                                                     AS qty
    FROM orders o
    , LATERAL FLATTEN(INPUT => SPLIT(NULLIF(o."exclusions", ''), ',')) xt
    WHERE TRIM(xt.value) IS NOT NULL
),

/* ------------------------------------------------------------ */
/* 4.  Net quantity of each topping after adds/removals         */
/* ------------------------------------------------------------ */
all_toppings AS (
    SELECT * FROM recipe_toppings
    UNION ALL
    SELECT * FROM extra_toppings
    UNION ALL
    SELECT * FROM exclusion_toppings
),
net_toppings AS (
    SELECT
        row_id,
        topping_id,
        SUM(qty) AS qty
    FROM all_toppings
    GROUP BY row_id, topping_id
    HAVING SUM(qty) > 0
),

/* ------------------------------------------------------------ */
/* 5.  Convert IDs to names and add “2x …” prefixes             */
/* ------------------------------------------------------------ */
named_toppings AS (
    SELECT
        n.row_id,
        tp."topping_name",
        CASE
            WHEN n.qty > 1
                THEN CONCAT(n.qty::VARCHAR, 'x ', tp."topping_name")
            ELSE tp."topping_name"
        END                                                 AS topping_label
    FROM net_toppings n
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS tp
          ON tp."topping_id" = n.topping_id
),

/* ------------------------------------------------------------ */
/* 6.  Collapse toppings into a comma-separated list            */
/* ------------------------------------------------------------ */
ingredient_strings AS (
    SELECT
        row_id,
        ARRAY_TO_STRING(
            ARRAY_AGG(topping_label) WITHIN GROUP (ORDER BY "topping_name"),
            ', '
        )                                                   AS ingredients
    FROM named_toppings
    GROUP BY row_id
)

/* ------------------------------------------------------------ */
/* 7.  Final result                                             */
/* ------------------------------------------------------------ */
SELECT
    o.row_id,
    o."order_id",
    o."customer_id",
    COALESCE(pn."pizza_name",
             CASE WHEN o.pizza_id = 1 THEN 'Meatlovers' ELSE 'Other' END)      AS pizza_name,
    CONCAT(
        COALESCE(pn."pizza_name",
                 CASE WHEN o.pizza_id = 1 THEN 'Meatlovers' ELSE 'Other' END),
        ': ',
        COALESCE(ing.ingredients, '')
    )                                                                         AS final_ingredients
FROM orders o
LEFT JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES pn
       ON pn."pizza_id" = o.pizza_id
LEFT JOIN ingredient_strings ing
       ON ing.row_id = o.row_id
ORDER BY o.row_id;