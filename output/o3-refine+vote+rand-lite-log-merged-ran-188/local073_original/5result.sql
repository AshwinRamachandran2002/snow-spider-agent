WITH 
/*------------------------------------------------------
Split the comma‑separated recipes into one row per topping
------------------------------------------------------*/
RECURSIVE recipe_expanded(pizza_id,topping_id,rest) AS (
    /* 1st piece of every recipe string */
    SELECT
        pizza_id,
        CAST( TRIM( SUBSTR(toppings,1, INSTR(toppings||',',',')-1) ) AS INTEGER),
        SUBSTR(toppings||',', INSTR(toppings||',',',')+1)
    FROM pizza_recipes

    UNION ALL

    /* remaining pieces */
    SELECT
        pizza_id,
        CASE                                    /* stop when nothing left   */
             WHEN rest=''        THEN NULL
             ELSE CAST( TRIM( SUBSTR(rest,1, INSTR(rest,',')-1) ) AS INTEGER)
        END,
        CASE
             WHEN rest=''        THEN ''
             ELSE SUBSTR(rest, INSTR(rest,',')+1)
        END
    FROM recipe_expanded
    WHERE rest<>''
),
recipe_toppings AS (
    SELECT pizza_id, topping_id
    FROM   recipe_expanded
    WHERE  topping_id IS NOT NULL
),

/*------------------------------------------------------
Map a row_id for every order (taken from the extras / 
exclusions tables when present, otherwise fall back to
the order_id itself)
------------------------------------------------------*/
row_id_map AS (
    SELECT order_id, MIN(row_id) AS row_id
    FROM (
          SELECT order_id,row_id FROM pizza_get_extras
          UNION ALL
          SELECT order_id,row_id FROM pizza_get_exclusions
    )
    GROUP BY order_id
),

/*------------------------------------------------------
All customer orders with a usable row_id and a normalized
pizza_id (1 = Meatlovers, 2 = everything else)
------------------------------------------------------*/
orders AS (
    SELECT
        COALESCE(rm.row_id, pco.order_id)          AS row_id,
        pco.order_id,
        pco.customer_id,
        pn.pizza_name,
        CASE WHEN pn.pizza_name='Meatlovers' THEN 1 ELSE 2 END AS mapped_pizza_id
    FROM  pizza_customer_orders  pco
    JOIN  pizza_names            pn  ON pn.pizza_id = pco.pizza_id
    LEFT  JOIN row_id_map        rm  ON rm.order_id = pco.order_id
),

/*------------------------------------------------------
Counts coming from the standard recipe (always +1)
------------------------------------------------------*/
standard AS (
    SELECT o.row_id,o.order_id,o.customer_id,o.pizza_name,
           rt.topping_id, 1 AS cnt
    FROM   orders o
    JOIN   recipe_toppings rt ON rt.pizza_id = o.mapped_pizza_id
),

/*------------------------------------------------------
Counts coming from extras  ( +extras_count )
------------------------------------------------------*/
extras AS (
    SELECT o.row_id,o.order_id,o.customer_id,o.pizza_name,
           e.extras AS topping_id,
           COALESCE(e.extras_count,1) AS cnt
    FROM   orders o
    JOIN   pizza_get_extras e ON e.order_id = o.order_id
),

/*------------------------------------------------------
Counts coming from exclusions ( −1 each )
------------------------------------------------------*/
exclusions AS (
    SELECT o.row_id,o.order_id,o.customer_id,o.pizza_name,
           ex.exclusions AS topping_id,
           -1 AS cnt
    FROM   orders o
    JOIN   pizza_get_exclusions ex ON ex.order_id = o.order_id
),

/*------------------------------------------------------
Net topping counts per order (remove if count ≤ 0)
------------------------------------------------------*/
topping_totals AS (
    SELECT row_id,order_id,customer_id,pizza_name,topping_id,
           SUM(cnt) AS total_cnt
    FROM (
          SELECT * FROM standard
          UNION ALL
          SELECT * FROM extras
          UNION ALL
          SELECT * FROM exclusions
    )
    GROUP BY row_id,order_id,customer_id,pizza_name,topping_id
    HAVING SUM(cnt) > 0
),

/*------------------------------------------------------
Build the alphabetically‑ordered ingredient string  
(prefix with ‘2x ’ where a topping appears twice)
------------------------------------------------------*/
order_ingredients AS (
    SELECT
        row_id,
        order_id,
        customer_id,
        pizza_name,
        ( SELECT GROUP_CONCAT(
                   CASE WHEN tt2.total_cnt>1
                        THEN '2x '||pt.topping_name
                        ELSE            pt.topping_name
                   END
                   , ', '
                 )
          FROM   topping_totals tt2
          JOIN   pizza_toppings pt ON pt.topping_id = tt2.topping_id
          WHERE  tt2.row_id  = tt.row_id
            AND  tt2.order_id= tt.order_id
          ORDER  BY pt.topping_name
        ) AS ingredient_list
    FROM topping_totals tt
    GROUP BY row_id,order_id,customer_id,pizza_name
)

/*------------------------------------------------------
Final required output
------------------------------------------------------*/
SELECT
    row_id,
    order_id,
    customer_id,
    pizza_name,
    pizza_name || ': ' || ingredient_list AS final_ingredients
FROM   order_ingredients
ORDER  BY row_id, order_id;