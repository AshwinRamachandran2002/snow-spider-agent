WITH RECURSIVE
order_base AS (         -- one record per original order
    SELECT
        o.order_id                      AS row_id,          -- row id = order id
        o.order_id,
        o.customer_id,
        CASE WHEN o.pizza_id = 1 THEN 1 ELSE 2 END AS std_pizza_id,
        pn.pizza_name,
        o.order_time,
        REPLACE(IFNULL(o.exclusions,''),' ','') AS excl_str,
        REPLACE(IFNULL(o.extras,''),' ','')     AS extra_str,
        REPLACE(pr.toppings,' ','')             AS std_str
    FROM pizza_clean_customer_orders o
    JOIN pizza_names   pn ON (CASE WHEN o.pizza_id = 1 THEN 1 ELSE 2 END) = pn.pizza_id
    JOIN pizza_recipes pr ON (CASE WHEN o.pizza_id = 1 THEN 1 ELSE 2 END) = pr.pizza_id
),

/* ---------- split the standard recipe list ---------- */
std_split(order_id,topping_id,rest) AS (
    SELECT
        ob.order_id,
        CAST(substr(ob.std_str,1,instr(ob.std_str||',',',')-1) AS INTEGER),
        substr(ob.std_str||',',instr(ob.std_str||',',',')+1)
    FROM order_base ob
    UNION ALL
    SELECT
        order_id,
        CAST(substr(rest,1,instr(rest,',')-1) AS INTEGER),
        substr(rest,instr(rest,',')+1)
    FROM std_split
    WHERE rest <> ''
),

/* ---------- split the extras list ---------- */
extras_start AS (SELECT * FROM order_base WHERE extra_str <> ''),
extra_split(order_id,topping_id,rest) AS (
    SELECT
        es.order_id,
        CAST(substr(es.extra_str,1,instr(es.extra_str||',',',')-1) AS INTEGER),
        substr(es.extra_str||',',instr(es.extra_str||',',',')+1)
    FROM extras_start es
    UNION ALL
    SELECT
        order_id,
        CAST(substr(rest,1,instr(rest,',')-1) AS INTEGER),
        substr(rest,instr(rest,',')+1)
    FROM extra_split
    WHERE rest <> ''
),

/* ---------- split the exclusions list ---------- */
excl_start AS (SELECT * FROM order_base WHERE excl_str <> ''),
excl_split(order_id,topping_id,rest) AS (
    SELECT
        es.order_id,
        CAST(substr(es.excl_str,1,instr(es.excl_str||',',',')-1) AS INTEGER),
        substr(es.excl_str||',',instr(es.excl_str||',',',')+1)
    FROM excl_start es
    UNION ALL
    SELECT
        order_id,
        CAST(substr(rest,1,instr(rest,',')-1) AS INTEGER),
        substr(rest,instr(rest,',')+1)
    FROM excl_split
    WHERE rest <> ''
),

/* ---------- count appearances (recipe + extras) ---------- */
ingredient_counts AS (
    SELECT order_id, topping_id, COUNT(*) AS cnt
    FROM (
          SELECT order_id, topping_id FROM std_split
          UNION ALL
          SELECT order_id, topping_id FROM extra_split
    )
    GROUP BY order_id, topping_id
),

/* ---------- remove the excluded toppings ---------- */
final_counts AS (
    SELECT ic.*
    FROM ingredient_counts ic
    LEFT JOIN excl_split ex
           ON ic.order_id   = ex.order_id
          AND ic.topping_id = ex.topping_id
    WHERE ex.topping_id IS NULL
),

/* ---------- build the final ingredient string per order ---------- */
final_strings AS (
    SELECT
        ob.order_id,
        GROUP_CONCAT(
            CASE
                WHEN fc.cnt > 1
                    THEN printf('%dx %s', fc.cnt, pt.topping_name)
                ELSE pt.topping_name
            END,
            ', '
        ) AS topping_list
    FROM order_base ob
    JOIN final_counts   fc ON fc.order_id = ob.order_id
    JOIN pizza_toppings pt ON pt.topping_id = fc.topping_id
    GROUP BY ob.order_id
)

SELECT
    ob.row_id,
    ob.order_id,
    ob.customer_id,
    ob.pizza_name,
    ob.pizza_name || ': ' || IFNULL(fs.topping_list,'') AS final_ingredients
FROM order_base  ob
LEFT JOIN final_strings fs USING (order_id)
GROUP BY ob.row_id, ob.order_id, ob.pizza_name, ob.order_time
ORDER BY ob.row_id;