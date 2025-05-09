/* -----------------------------------------------------------
   Produce one line per pizza order that contains
   ① row_id (taken from the extras / exclusions tables)
   ② order_id
   ③ customer_id
   ④ pizza name
   ⑤ pizza‑name followed by “: ” plus the alphabetical list of
      final ingredients (2x, 3x … if a topping occurs >1 time)
---------------------------------------------------------------- */
WITH
/* 1.  basic order information                                  */
orders AS (
    SELECT
        c.order_id,
        c.customer_id,
        CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
        pn.pizza_name,
        c.order_time
    FROM  pizza_clean_customer_orders  AS c
    JOIN  pizza_names                  AS pn USING (pizza_id)
),
/* 2.  split the recipe toppings into one row each              */
recipe_split AS (
    SELECT
        o.order_id,
        CAST( TRIM( j.value ) AS INTEGER )          AS topping_id,
        1                                           AS cnt
    FROM orders                AS o
    JOIN pizza_recipes         AS r  ON r.pizza_id = o.pizza_id
    JOIN json_each( '['||r.toppings||']' ) AS j           -- turns “1, 2, 3” → JSON array
),
/* 3.  extras and exclusions already come row‑wise              */
extras AS (
    SELECT  row_id,
            order_id,
            extras           AS topping_id,
            extras_count     AS cnt
    FROM    pizza_get_extras
),
exclusions AS (
    SELECT  order_id,
            exclusions       AS topping_id
    FROM    pizza_get_exclusions
),
/* 4.  collect every topping that could appear in an order      */
all_toppings AS (
    SELECT DISTINCT order_id, topping_id FROM recipe_split
    UNION
    SELECT DISTINCT order_id, topping_id FROM extras
    UNION
    SELECT DISTINCT order_id, topping_id FROM exclusions
),
/* 5.  work out the final count of each topping                 */
counts AS (
    SELECT
        t.order_id,
        t.topping_id,
        /* recipe part that SURVIVES (not excluded) */
        CASE WHEN ex.topping_id IS NULL
             THEN IFNULL( (SELECT SUM(cnt) FROM recipe_split
                           WHERE order_id=t.order_id AND topping_id=t.topping_id), 0 )
             ELSE 0
        END
        +
        /* plus the extras                                        */
        IFNULL( (SELECT SUM(cnt) FROM extras
                 WHERE order_id=t.order_id AND topping_id=t.topping_id), 0 )  AS total_cnt
    FROM  all_toppings  AS t
    LEFT JOIN exclusions AS ex
           ON  ex.order_id   = t.order_id
           AND ex.topping_id = t.topping_id
),
/* 6.  turn counts into printable ingredient strings            */
ingredient_strings AS (
    SELECT
        c.order_id,
        CASE
            WHEN c.total_cnt > 1
            THEN printf('%dx %s', c.total_cnt, pt.topping_name)
            ELSE                pt.topping_name
        END   AS ingredient
    FROM   counts          AS c
    JOIN   pizza_toppings  AS pt ON pt.topping_id = c.topping_id
    WHERE  c.total_cnt > 0
),
/* 7.  alphabetically ordered, comma‑separated ingredient list  */
ingredient_list AS (
    SELECT order_id,
           GROUP_CONCAT( ingredient, ', ' )  AS ingredients
    FROM (
        SELECT order_id, ingredient
        FROM   ingredient_strings
        ORDER BY order_id, ingredient        -- guarantees alphabetical order
    )
    GROUP BY order_id
),
/* 8.  fetch the row_id to be shown (from extras → exclusions)  */
row_tag AS (
    SELECT
        o.order_id,
        COALESCE( (SELECT MAX(row_id) FROM pizza_get_extras     e WHERE e.order_id = o.order_id),
                  (SELECT MAX(row_id) FROM pizza_get_exclusions x WHERE x.order_id = o.order_id)
                ) AS row_id
    FROM orders AS o
)
/* 9.  final report                                             */
SELECT
    rt.row_id,
    o.order_id,
    o.customer_id,
    o.pizza_name,
    o.pizza_name || ': ' || il.ingredients            AS final_ingredients
FROM   orders          AS o
JOIN   ingredient_list AS il ON il.order_id = o.order_id
LEFT JOIN row_tag      AS rt ON rt.order_id = o.order_id
ORDER BY rt.row_id, o.order_id;