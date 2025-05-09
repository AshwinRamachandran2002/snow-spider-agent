WITH orders AS (                          -- every original order once
    SELECT
        ROW_NUMBER() OVER (ORDER BY pc.order_id)              AS row_id,
        pc.order_id,
        pc.customer_id,
        CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id_fixed,
        pn.pizza_name,
        pc.exclusions,
        pc.extras
    FROM pizza_customer_orders pc
    JOIN pizza_names pn
          ON pn.pizza_id = pc.pizza_id
),
-----------------------------------------------------------------
-- 1. standard toppings coming from the recipe ------------------
-----------------------------------------------------------------
standard AS (
    SELECT o.row_id,
           o.order_id,
           CAST(j.value AS INTEGER) AS topping_id
    FROM   orders o
    JOIN   pizza_recipes pr
           ON pr.pizza_id = o.pizza_id_fixed
    JOIN   json_each('[' || REPLACE(pr.toppings,' ','') || ']') j
),
-----------------------------------------------------------------
-- 2. extras and exclusions supplied by the customer ------------
-----------------------------------------------------------------
extras_raw AS (
    SELECT o.row_id,
           o.order_id,
           CAST(j.value AS INTEGER) AS topping_id
    FROM   orders o
    JOIN   json_each('[' || REPLACE(COALESCE(o.extras,''),' ','') || ']') j
    WHERE  COALESCE(o.extras,'') <> ''
      AND  LOWER(COALESCE(o.extras,'')) <> 'null'
),
exclusions AS (
    SELECT o.row_id,
           o.order_id,
           CAST(j.value AS INTEGER) AS topping_id
    FROM   orders o
    JOIN   json_each('[' || REPLACE(COALESCE(o.exclusions,''),' ','') || ']') j
    WHERE  COALESCE(o.exclusions,'') <> ''
      AND  LOWER(COALESCE(o.exclusions,'')) <> 'null'
),
-----------------------------------------------------------------
-- 3. keep only standard toppings that are NOT excluded ---------
-----------------------------------------------------------------
standard_kept AS (
    SELECT s.*
    FROM   standard s
    LEFT   JOIN exclusions e
           ON e.order_id   = s.order_id
          AND e.topping_id = s.topping_id
    WHERE  e.topping_id IS NULL
),
-----------------------------------------------------------------
-- 4. combine (standard – exclusions) with all extras -----------
-----------------------------------------------------------------
merged AS (
    SELECT row_id, order_id, topping_id FROM standard_kept
    UNION ALL
    SELECT row_id, order_id, topping_id FROM extras_raw
),
-----------------------------------------------------------------
-- 5. how many times each topping finally appears ----------------
-----------------------------------------------------------------
qty AS (
    SELECT row_id,
           order_id,
           topping_id,
           COUNT(*) AS qty
    FROM   merged
    GROUP  BY row_id, order_id, topping_id
),
-----------------------------------------------------------------
-- 6. build the ingredient text in alphabetical order -----------
-----------------------------------------------------------------
ingredients_text AS (
    SELECT
        o.row_id,
        o.order_id,
        o.customer_id,
        o.pizza_name,
        (
            SELECT GROUP_CONCAT(
                CASE WHEN sub.qty > 1
                     THEN sub.qty || 'x ' || sub.topping_name
                     ELSE sub.topping_name
                END,
                ', '
            )
            FROM (
                SELECT q.qty,
                       pt.topping_name
                FROM   qty q
                JOIN   pizza_toppings pt
                       ON pt.topping_id = q.topping_id
                WHERE  q.row_id = o.row_id
                ORDER  BY pt.topping_name               -- alphabetical
            ) sub
        ) AS ingredients_str
    FROM   orders o
)
-----------------------------------------------------------------
-- 7. final result ----------------------------------------------
-----------------------------------------------------------------
SELECT
    row_id,
    order_id,
    customer_id,
    pizza_name,
    pizza_name || ': ' || ingredients_str AS final_ingredients
FROM   ingredients_text
ORDER  BY row_id;