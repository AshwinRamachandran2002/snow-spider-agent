WITH delivered_orders AS (
    -- orders that were actually delivered (not cancelled)
    SELECT co.order_id,
           co.pizza_id
    FROM   pizza_clean_runner_orders  ro
    JOIN   pizza_clean_customer_orders co
           ON co.order_id = ro.order_id
    WHERE  ro.cancellation IS NULL
),
/* ------------------------------------------------------------------  
   Break the recipe topping lists (e.g. '1, 2, 3') into one row
   per topping for every delivered order.
   ------------------------------------------------------------------ */
recipes_string AS (
    SELECT d.order_id,
           pr.toppings || ',' AS topping_list          -- add final comma for easy split
    FROM   delivered_orders d
    JOIN   pizza_recipes pr
           ON pr.pizza_id = d.pizza_id
),
split_recipes(order_id,topping_id,rest) AS (
    /* first slice */
    SELECT order_id,
           trim(substr(topping_list,0,instr(topping_list,','))) AS topping_id,
           substr(topping_list,instr(topping_list,',')+1)       AS rest
    FROM   recipes_string

    UNION ALL                -- keep slicing until nothing left
    SELECT order_id,
           trim(substr(rest,0,instr(rest,','))),
           substr(rest,instr(rest,',')+1)
    FROM   split_recipes
    WHERE  rest <> ''
),
recipe_toppings AS (
    SELECT order_id,
           CAST(topping_id AS INTEGER) AS topping_id,
           1 AS qty                     -- each recipe topping counts once
    FROM   split_recipes
    WHERE  topping_id <> ''
),
/* ------------------------------------------------------------------  
   Extra & exclusion adjustments (already exploded in helper tables)
   ------------------------------------------------------------------ */
extras_toppings AS (
    SELECT e.order_id,
           e.extras        AS topping_id,
           e.extras_count  AS qty
    FROM   pizza_get_extras e
    JOIN   delivered_orders d
           ON d.order_id = e.order_id
),
exclusions_toppings AS (
    SELECT x.order_id,
           x.exclusions            AS topping_id,
          -x.total_exclusions      AS qty   -- subtract excluded units
    FROM   pizza_get_exclusions x
    JOIN   delivered_orders d
           ON d.order_id = x.order_id
),
/* ------------------------------------------------------------------  
   Combine recipe, extras, and exclusions
   ------------------------------------------------------------------ */
all_toppings AS (
    SELECT topping_id, qty FROM recipe_toppings
    UNION ALL
    SELECT topping_id, qty FROM extras_toppings
    UNION ALL
    SELECT topping_id, qty FROM exclusions_toppings
)
/* ------------------------------------------------------------------  
   Final ingredient usage summary
   ------------------------------------------------------------------ */
SELECT  pt.topping_name   AS ingredient,
        SUM(a.qty)        AS quantity
FROM    all_toppings a
JOIN    pizza_toppings pt
        ON pt.topping_id = a.topping_id
GROUP BY pt.topping_id, pt.topping_name
ORDER BY pt.topping_name;