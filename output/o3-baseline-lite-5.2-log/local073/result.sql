/*  ---------------------------------------------------------
    For every pizza order work out the final list of toppings:
      – start with the recipe toppings
      – remove every topping mentioned in exclusions
      – add every topping mentioned in extras (duplicates allowed)
    The toppings must be shown alphabetically, prefixed with “2x”
    (or 3x …) if the same topping finally appears more than once.
    The answer is one row per pizza order and is returned in
    ascending order of the row‑id taken from pizza_customer_orders.
    ---------------------------------------------------------   */

WITH
/* every order – give Meatlovers id 1, all others 2                */
base_orders AS (
    SELECT
        rowid                                   AS row_id,
        order_id,
        customer_id,
        CASE WHEN pizza_id = 1 THEN 1 ELSE 2 END  AS pizza_id,
        exclusions,
        extras,
        order_time
    FROM pizza_customer_orders
),

/* split the recipe string to one row per topping                  */
recipe_toppings AS (
    SELECT
        pr.pizza_id,
        CAST( json_each.value AS INTEGER ) AS topping_id
    FROM pizza_recipes  pr,
         json_each( '[' || pr.toppings || ']' )
),

/* standard toppings that belong to every order                    */
standard AS (
    SELECT
        bo.row_id,
        bo.order_id,
        rt.topping_id,
        1 AS cnt                         /* one of each from recipe */
    FROM base_orders     bo
    JOIN recipe_toppings rt
         ON rt.pizza_id = bo.pizza_id
),

/* toppings to be excluded                                         */
excl_list AS (
    SELECT
        bo.row_id,
        bo.order_id,
        CAST( json_each.value AS INTEGER ) AS topping_id
    FROM base_orders bo
    JOIN json_each(
            CASE
                WHEN bo.exclusions IS NULL
                     OR bo.exclusions IN ('', 'null') THEN '[]'
                ELSE '[' || bo.exclusions || ']'
            END )
),

/* toppings to be added (each mention counts once)                 */
extra_list AS (
    SELECT
        bo.row_id,
        bo.order_id,
        CAST( json_each.value AS INTEGER ) AS topping_id,
        1 AS cnt                         /* one extra per mention   */
    FROM base_orders bo
    JOIN json_each(
            CASE
                WHEN bo.extras IS NULL
                     OR bo.extras IN ('', 'null') THEN '[]'
                ELSE '[' || bo.extras || ']'
            END )
),

/* keep the standard toppings that were NOT excluded               */
standard_kept AS (
    SELECT s.*
    FROM   standard s
    LEFT   JOIN excl_list x
           ON  x.row_id    = s.row_id
           AND x.order_id  = s.order_id
           AND x.topping_id = s.topping_id
    WHERE  x.topping_id IS NULL
),

/* combine what is kept with what is extra and total the counts    */
combined AS (
    SELECT row_id, order_id, topping_id, SUM(cnt) AS cnt
    FROM (
        SELECT row_id, order_id, topping_id, cnt FROM standard_kept
        UNION ALL
        SELECT row_id, order_id, topping_id, cnt FROM extra_list
    )
    GROUP BY row_id, order_id, topping_id
    HAVING SUM(cnt) > 0
),

/* turn counts into display strings (e.g. “2x Bacon”)              */
ingredient_words AS (
    SELECT
        c.row_id,
        c.order_id,
        CASE
            WHEN c.cnt > 1 THEN c.cnt || 'x ' || pt.topping_name
            ELSE                   pt.topping_name
        END                                   AS ingredient
    FROM combined       c
    JOIN pizza_toppings pt
         ON pt.topping_id = c.topping_id
),

/* concatenate the words, keeping alphabetical order               */
ingredient_lists AS (
    SELECT
        iw.row_id,
        iw.order_id,
        ( SELECT GROUP_CONCAT(ingredient, ', ')
          FROM   ( SELECT ingredient
                   FROM   ingredient_words
                   WHERE  row_id  = iw.row_id
                   AND    order_id = iw.order_id
                   ORDER  BY ingredient )
        ) AS ingredients
    FROM ingredient_words iw
    GROUP BY iw.row_id, iw.order_id
),

/* final output                                                    */
final AS (
    SELECT
        bo.row_id,
        bo.order_id,
        bo.customer_id,
        pn.pizza_name,
        pn.pizza_name || ': ' || COALESCE(il.ingredients, '') AS final_ingredients
    FROM base_orders      bo
    JOIN pizza_names      pn  ON pn.pizza_id = bo.pizza_id
    LEFT JOIN ingredient_lists il
           ON il.row_id   = bo.row_id
          AND il.order_id = bo.order_id
)
SELECT
    row_id,
    order_id,
    customer_id,
    pizza_name,
    final_ingredients
FROM   final
ORDER  BY row_id;