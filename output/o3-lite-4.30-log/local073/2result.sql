WITH
/* -------------------------------------------------
   1. every pizza line‑item in an order together with
      a “row_id” (taken from extras first, otherwise
      exclusions, otherwise 0)
------------------------------------------------- */
orders AS (
    SELECT  o.order_id,
            o.customer_id,
            o.pizza_id,
            o.order_time,
            pn.pizza_name,
            COALESCE(extr.row_id_extra,
                     excl.row_id_excl,
                     0)                         AS row_id
    FROM   pizza_customer_orders  AS o
    JOIN   pizza_names            AS pn   USING (pizza_id)

    LEFT JOIN (SELECT order_id,
                      MIN(row_id) AS row_id_extra
               FROM   pizza_get_extras
               GROUP  BY order_id)            AS extr
           ON extr.order_id = o.order_id

    LEFT JOIN (SELECT order_id,
                      MIN(row_id) AS row_id_excl
               FROM   pizza_get_exclusions
               GROUP  BY order_id)            AS excl
           ON excl.order_id = o.order_id
),

/* -------------------------------------------------
   2. standard toppings for each pizza line‑item
------------------------------------------------- */
recipe_toppings AS (
    SELECT  o.row_id,
            o.order_id,
            o.pizza_id,
            o.pizza_name,
            CAST(j.value AS INTEGER) AS topping_id,
            1                        AS cnt           -- one of each in base recipe
    FROM   orders              AS o
    JOIN   pizza_recipes       AS pr   USING (pizza_id)
    JOIN   json_each('[' || pr.toppings || ']') AS j
),

/* -------------------------------------------------
   3. exclusions per order
------------------------------------------------- */
exclusions AS (
    SELECT  order_id,
            exclusions AS topping_id
    FROM    pizza_get_exclusions
),

/* -------------------------------------------------
   4. base recipe after removing exclusions
------------------------------------------------- */
base_after_excl AS (
    SELECT  rt.row_id,
            rt.order_id,
            rt.pizza_id,
            rt.pizza_name,
            rt.topping_id,
            rt.cnt
    FROM    recipe_toppings   AS rt
    LEFT JOIN exclusions      AS ex
           ON ex.order_id  = rt.order_id
          AND ex.topping_id = rt.topping_id
    WHERE   ex.topping_id IS NULL
),

/* -------------------------------------------------
   5. extras (may add the same topping once or twice)
------------------------------------------------- */
extras AS (
    SELECT  o.row_id,
            e.order_id,
            o.pizza_id,
            o.pizza_name,
            e.extras        AS topping_id,
            e.extras_count  AS cnt
    FROM   pizza_get_extras  AS e
    JOIN   orders            AS o  ON o.order_id = e.order_id
),

/* -------------------------------------------------
   6. combine base recipe (after exclusions) + extras
------------------------------------------------- */
all_counts AS (
    SELECT * FROM base_after_excl
    UNION ALL
    SELECT * FROM extras
),
final_counts AS (
    SELECT  row_id,
            order_id,
            pizza_id,
            pizza_name,
            topping_id,
            SUM(cnt) AS total_cnt
    FROM    all_counts
    GROUP BY row_id, order_id, pizza_id, pizza_name, topping_id
),

/* -------------------------------------------------
   7. turn counts into printable strings
------------------------------------------------- */
topping_strings AS (
    SELECT  fc.row_id,
            fc.order_id,
            fc.pizza_id,
            fc.pizza_name,
            CASE
              WHEN fc.total_cnt > 1
                   THEN printf('%dx %s', fc.total_cnt, pt.topping_name)
              ELSE pt.topping_name
            END                       AS topping_str,
            pt.topping_name           AS sort_name
    FROM    final_counts   AS fc
    JOIN    pizza_toppings AS pt ON pt.topping_id = fc.topping_id
),

/* -------------------------------------------------
   8. concatenate toppings in alphabetic order
------------------------------------------------- */
toppings_concat AS (
    SELECT  row_id,
            order_id,
            pizza_id,
            pizza_name,
            GROUP_CONCAT(topping_str, ', ') AS toppings_list
    FROM   (
            SELECT row_id,
                   order_id,
                   pizza_id,
                   pizza_name,
                   topping_str,
                   sort_name
            FROM   topping_strings
            ORDER  BY row_id, order_id, pizza_id, sort_name
          )
    GROUP BY row_id, order_id, pizza_id, pizza_name
)

/* -------------------------------------------------
   9. final answer
------------------------------------------------- */
SELECT
    o.row_id,
    o.order_id,
    o.customer_id,
    o.order_time,
    o.pizza_name,
    CASE WHEN o.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
    o.pizza_name || ': ' || COALESCE(tc.toppings_list, '')  AS final_ingredients
FROM   orders            AS o
LEFT JOIN toppings_concat AS tc
       ON tc.row_id    = o.row_id
      AND tc.order_id  = o.order_id
      AND tc.pizza_id  = o.pizza_id
GROUP BY o.row_id, o.order_id, o.customer_id, o.order_time, o.pizza_name, o.pizza_id
ORDER BY o.row_id ASC;