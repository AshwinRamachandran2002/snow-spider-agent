WITH RECURSIVE
/* ------------------------------------------------------------------ */
/* 1.  Each pizza order – create our own sequential row_id             */
orders AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY c.order_time, c.order_id, c.pizza_id) AS row_id,
        c.order_id,
        c.customer_id,
        c.pizza_id                    AS recipe_pizza_id,   -- real id for recipe look-up
        pn.pizza_name,
        CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS mapped_pizza_id,
        c.order_time
    FROM   pizza_customer_orders AS c
    JOIN   pizza_names           AS pn ON pn.pizza_id = c.pizza_id
),
/* ------------------------------------------------------------------ */
/* 2.  Split every recipe string into individual topping_id rows       */
std_split(row_id, order_id, topping_id, rest) AS (
    -- first segment from the recipe string
    SELECT  o.row_id,
            o.order_id,
            CAST(TRIM(SUBSTR(pr.toppings,
                             1,
                             INSTR(pr.toppings||',',',')-1)) AS INTEGER)        AS topping_id,
            SUBSTR(pr.toppings||',',
                   INSTR(pr.toppings||',',',')+1)                              AS rest
    FROM   orders        AS o
    JOIN   pizza_recipes AS pr ON pr.pizza_id = o.recipe_pizza_id

    UNION ALL
    -- middle segments while commas remain
    SELECT  row_id,
            order_id,
            CAST(TRIM(SUBSTR(rest,1,INSTR(rest,',')-1)) AS INTEGER),
            SUBSTR(rest,INSTR(rest,',')+1)
    FROM   std_split
    WHERE  rest LIKE '%,%'

    UNION ALL
    -- final segment (no comma left)
    SELECT  row_id,
            order_id,
            CAST(TRIM(rest) AS INTEGER),
            ''
    FROM   std_split
    WHERE  rest NOT LIKE '%,%' AND rest <> ''
),
/* ------------------------------------------------------------------ */
/* 3.  Toppings the customer asked to remove                           */
excl AS (
    SELECT  order_id,
            CAST(exclusions AS INTEGER) AS topping_id
    FROM    pizza_get_exclusions
    GROUP BY order_id, exclusions
),
/* Standard toppings minus exclusions                                  */
std_no_excl AS (
    SELECT  ss.row_id,
            ss.order_id,
            ss.topping_id,
            1 AS cnt
    FROM    std_split ss
    LEFT JOIN excl
           ON excl.order_id   = ss.order_id
          AND excl.topping_id = ss.topping_id
    WHERE   excl.topping_id IS NULL
),
/* ------------------------------------------------------------------ */
/* 4.  Count of extra toppings added                                   */
extras_cnt AS (
    SELECT  order_id,
            CAST(extras AS INTEGER) AS topping_id,
            SUM(extras_count)       AS cnt
    FROM    pizza_get_extras
    GROUP BY order_id, extras
),
extras_rows AS (
    SELECT  o.row_id,
            ec.order_id,
            ec.topping_id,
            ec.cnt
    FROM    orders o
    JOIN    extras_cnt ec ON ec.order_id = o.order_id
),
/* ------------------------------------------------------------------ */
/* 5.  Merge standard (after exclusions) with extras                   */
combined AS (
    SELECT * FROM std_no_excl
    UNION ALL
    SELECT * FROM extras_rows
),
final_counts AS (
    SELECT  row_id,
            topping_id,
            SUM(cnt) AS cnt
    FROM    combined
    GROUP BY row_id, topping_id
),
/* ------------------------------------------------------------------ */
/* 6.  Convert counts into readable strings                            */
topping_strings AS (
    SELECT  fc.row_id,
            pt.topping_name,
            CASE WHEN fc.cnt > 1
                 THEN '2x ' || pt.topping_name
                 ELSE        pt.topping_name
            END AS topping_string
    FROM    final_counts fc
    JOIN    pizza_toppings pt ON pt.topping_id = fc.topping_id
),
/* ------------------------------------------------------------------ */
/* 7.  Alphabetically order and concatenate toppings per order         */
ingredients AS (
    SELECT  row_id,
            GROUP_CONCAT(topping_string, ', ') AS ingredient_list
    FROM   (
        SELECT  row_id,
                topping_name,
                topping_string
        FROM    topping_strings
        ORDER BY row_id, topping_name
    )
    GROUP BY row_id
)
/* ------------------------------------------------------------------ */
SELECT  o.row_id,
        o.order_id,
        o.customer_id,
        o.pizza_name,
        o.pizza_name || ': ' || ingredient_list AS final_ingredients
FROM    orders      AS o
JOIN    ingredients AS i USING (row_id)
ORDER BY o.row_id;