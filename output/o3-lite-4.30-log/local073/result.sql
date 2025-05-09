WITH
/* -------------------------------------------------------------
0.  unify every logical pizza line that has to be evaluated
    – duplicates coming from repeated rows in pizza_customer_orders
      are removed with DISTINCT
------------------------------------------------------------- */
orders AS (
    SELECT DISTINCT
           pc.order_id,
           pc.customer_id,
           pc.order_time,
           pc.pizza_id,
           pn.pizza_name,
           ge.row_id                       -- when EXTRAS exist
    FROM   pizza_customer_orders pc
    JOIN   pizza_names          pn ON pn.pizza_id = pc.pizza_id
    JOIN   pizza_get_extras     ge ON ge.order_id = pc.order_id

    UNION ALL
    SELECT DISTINCT
           pc.order_id,
           pc.customer_id,
           pc.order_time,
           pc.pizza_id,
           pn.pizza_name,
           gx.row_id                       -- only EXCLUSIONS
    FROM   pizza_customer_orders pc
    JOIN   pizza_names           pn ON pn.pizza_id = pc.pizza_id
    JOIN   pizza_get_exclusions  gx ON gx.order_id = pc.order_id
    WHERE  gx.row_id NOT IN (SELECT ge2.row_id
                             FROM   pizza_get_extras ge2
                             WHERE  ge2.order_id = pc.order_id)

    UNION ALL
    SELECT DISTINCT
           pc.order_id,
           pc.customer_id,
           pc.order_time,
           pc.pizza_id,
           pn.pizza_name,
           pc.order_id                     -- plain pizza (no extras or exclusions)
    FROM   pizza_customer_orders pc
    JOIN   pizza_names pn ON pn.pizza_id = pc.pizza_id
    WHERE  pc.order_id NOT IN (SELECT order_id FROM pizza_get_extras)
      AND  pc.order_id NOT IN (SELECT order_id FROM pizza_get_exclusions)
),
/* -------------------------------------------------------------
1. default recipe toppings – after removing any exclusions
------------------------------------------------------------- */
base_toppings AS (
    SELECT
        o.row_id, o.order_id, o.customer_id, o.order_time,
        o.pizza_name,
        CASE WHEN o.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END  AS pizza_id,
        pt.topping_id,
        1 AS qty
    FROM   orders         o
    JOIN   pizza_recipes  pr ON pr.pizza_id = o.pizza_id
    JOIN   pizza_toppings pt
           ON instr(','||REPLACE(pr.toppings,' ','')||',',
                    ','||pt.topping_id||',') > 0
    WHERE  pt.topping_id NOT IN (
              SELECT gx.exclusions
              FROM   pizza_get_exclusions gx
              WHERE  gx.order_id = o.order_id
                AND  gx.row_id   = o.row_id
           )
),
/* -------------------------------------------------------------
2. toppings added as extras (carry their own quantity)
------------------------------------------------------------- */
extra_toppings AS (
    SELECT
        o.row_id, o.order_id, o.customer_id, o.order_time,
        o.pizza_name,
        CASE WHEN o.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END  AS pizza_id,
        ge.extras        AS topping_id,
        ge.extras_count  AS qty
    FROM   orders            o
    JOIN   pizza_get_extras  ge
           ON ge.order_id = o.order_id
          AND ge.row_id   = o.row_id
),
/* -------------------------------------------------------------
3. merge base + extras, total quantity per topping
------------------------------------------------------------- */
topping_totals AS (
    SELECT
        row_id, order_id, customer_id, order_time,
        pizza_name, pizza_id,
        topping_id,
        SUM(qty) AS total_qty
    FROM (
        SELECT * FROM base_toppings
        UNION ALL
        SELECT * FROM extra_toppings
    )
    GROUP BY row_id, order_id, customer_id, order_time,
             pizza_name, pizza_id, topping_id
),
/* -------------------------------------------------------------
4. convert ids to names & prefix “2x ” where quantity > 1
------------------------------------------------------------- */
ingredient_words AS (
    SELECT
        tt.row_id, tt.order_id, tt.customer_id, tt.order_time,
        tt.pizza_name, tt.pizza_id,
        pt.topping_name,
        CASE WHEN tt.total_qty > 1
             THEN '2x ' || pt.topping_name
             ELSE        pt.topping_name
        END AS ingredient
    FROM   topping_totals tt
    JOIN   pizza_toppings pt ON pt.topping_id = tt.topping_id
),
/* -------------------------------------------------------------
5. assemble final ingredient string (alphabetical order)
------------------------------------------------------------- */
final_result AS (
    SELECT
        iw.row_id,
        iw.order_id,
        iw.customer_id,
        iw.order_time,
        iw.pizza_name,
        iw.pizza_id,
        iw.pizza_name || ': ' ||
        (SELECT GROUP_CONCAT(ingredient, ', ')
         FROM   (SELECT ingredient
                 FROM   ingredient_words iw2
                 WHERE  iw2.row_id   = iw.row_id
                   AND  iw2.order_id = iw.order_id
                   AND  iw2.pizza_id = iw.pizza_id
                 ORDER  BY iw2.topping_name)
        ) AS final_ingredients
    FROM  ingredient_words iw
    GROUP BY iw.row_id, iw.order_id, iw.customer_id,
             iw.order_time, iw.pizza_name, iw.pizza_id
)
/* -------------------------------------------------------------
6. required output
------------------------------------------------------------- */
SELECT
    row_id,
    order_id,
    customer_id,
    order_time,
    pizza_name,
    pizza_id,
    final_ingredients
FROM   final_result
ORDER  BY row_id;