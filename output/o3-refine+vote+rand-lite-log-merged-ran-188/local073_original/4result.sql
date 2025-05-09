WITH orders AS (              -- every original pizza order
    SELECT
        /*get a row_id if one exists in the extra / exclusion tables, otherwise fall back to order_id*/
        COALESCE(
            (SELECT ge.row_id FROM pizza_get_extras     ge WHERE ge.order_id = o.order_id LIMIT 1),
            (SELECT gx.row_id FROM pizza_get_exclusions gx WHERE gx.order_id = o.order_id LIMIT 1),
            o.order_id
        )                                           AS row_id,
        o.order_id,
        o.customer_id,
        /*force the requested pizza_id mapping*/
        CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
        pn.pizza_name,
        o.order_time
    FROM pizza_clean_customer_orders o
    JOIN pizza_names pn
          ON o.pizza_id = pn.pizza_id
),
/*---------- standard recipe toppings (1 of each) ----------------------------------*/
recipe_toppings AS (
    SELECT
        o.order_id,
        CAST(j.value AS INTEGER)  AS topping_id,
        1                         AS qty
    FROM orders o
    JOIN pizza_recipes pr
          ON pr.pizza_id = o.pizza_id
    /*turn the comma‑separated list into JSON then explode with json_each()*/
    JOIN json_each(
            '["' ||
            REPLACE(REPLACE(pr.toppings,' ','') , ',', '","') ||
            '"]'
         ) AS j
),
/*---------- extras (positive quantities) -------------------------------------------*/
extra_toppings AS (
    SELECT
        ge.order_id,
        ge.extras           AS topping_id,
        ge.extras_count     AS qty
    FROM pizza_get_extras ge
),
/*---------- exclusions (negative quantities) ---------------------------------------*/
exclusion_toppings AS (
    SELECT
        gx.order_id,
        gx.exclusions               AS topping_id,
        -gx.total_exclusions        AS qty          -- subtract these
    FROM pizza_get_exclusions gx
),
/*---------- gather every change and keep net positive qty --------------------------*/
all_changes AS (
    SELECT * FROM recipe_toppings
    UNION ALL
    SELECT * FROM extra_toppings
    UNION ALL
    SELECT * FROM exclusion_toppings
),
net_toppings AS (
    SELECT
        order_id,
        topping_id,
        SUM(qty) AS qty
    FROM all_changes
    GROUP BY order_id, topping_id
    HAVING SUM(qty) > 0                      -- only toppings that remain
),
/*---------- translate topping_id -> name, add “2x” etc -----------------------------*/
named_toppings AS (
    SELECT
        n.order_id,
        CASE
            WHEN n.qty > 1 THEN n.qty || 'x ' || pt.topping_name
            ELSE                   pt.topping_name
        END AS ingredient
    FROM net_toppings n
    JOIN pizza_toppings pt
          ON pt.topping_id = n.topping_id
),
/*---------- build one comma‑separated, alphabetically ordered list per order -------*/
ingredient_list AS (
    SELECT
        order_id,
        GROUP_CONCAT(ingredient, ', ') AS ingredients
    FROM (
        SELECT order_id, ingredient
        FROM   named_toppings
        ORDER  BY ingredient            -- alphabetical
    )
    GROUP BY order_id
)
/*========================== final output ===========================================*/
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    o.pizza_name,
    o.pizza_name || ': ' || COALESCE(il.ingredients,'') AS final_ingredients
FROM orders o
LEFT JOIN ingredient_list il
       ON il.order_id = o.order_id
/*one row per order as requested*/
GROUP BY o.row_id, o.order_id, o.pizza_name, o.order_time
ORDER BY o.row_id;