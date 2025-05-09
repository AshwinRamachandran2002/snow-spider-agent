WITH RECURSIVE
/* 1. delivered orders (not cancelled) */
delivered_orders AS (
    SELECT order_id
    FROM pizza_clean_runner_orders
    WHERE cancellation IS NULL
),

/* 2. pizza chosen for every delivered order */
customer_orders AS (
    SELECT c.order_id,
           c.pizza_id
    FROM   pizza_clean_customer_orders c
    JOIN   delivered_orders d USING (order_id)
),

/* 3. split the comma‑separated toppings list for every pizza
      into one row per (order_id , topping_id) */
recipe_split(order_id, topping_id, rest) AS (
    -- anchor (first topping)
    SELECT
        co.order_id,
        CAST( TRIM( SUBSTR(pr.toppings, 1,
                            INSTR(pr.toppings || ',', ',') - 1) ) AS INTEGER )  AS topping_id,
        SUBSTR(pr.toppings || ',', INSTR(pr.toppings || ',', ',') + 1)           AS rest
    FROM customer_orders  co
    JOIN pizza_recipes    pr  ON pr.pizza_id = co.pizza_id

    UNION ALL

    -- recursive step (next topping)
    SELECT
        order_id,
        CAST( TRIM( SUBSTR(rest, 1, INSTR(rest, ',') - 1) ) AS INTEGER ),
        SUBSTR(rest, INSTR(rest, ',') + 1)
    FROM recipe_split
    WHERE rest <> ''
),

/* 4. base toppings on each delivered pizza */
base_toppings AS (
    SELECT order_id, topping_id
    FROM   recipe_split
),

/* 5. toppings the customer asked to exclude */
exclusions AS (
    SELECT ge.order_id,
           ge.exclusions AS topping_id
    FROM   pizza_get_exclusions ge
    JOIN   delivered_orders      d  USING (order_id)
),

/* 6. extra toppings the customer added (qty may be > 1) */
extras AS (
    SELECT ge.order_id,
           ge.extras        AS topping_id,
           COALESCE(ge.extras_count, 1) AS qty
    FROM   pizza_get_extras ge
    JOIN   delivered_orders  d  USING (order_id)
),

/* 7. keep base toppings that were NOT excluded */
usable_base AS (
    SELECT b.topping_id,
           1 AS qty
    FROM   base_toppings b
    LEFT JOIN exclusions e
           ON  b.order_id  = e.order_id
           AND b.topping_id = e.topping_id
    WHERE  e.topping_id IS NULL
),

/* 8. merge base toppings and extras */
all_ingredients AS (
    SELECT topping_id, qty FROM usable_base
    UNION ALL
    SELECT topping_id, qty FROM extras
)

/* 9. final ingredient usage summary */
SELECT  pt.topping_name AS ingredient,
        SUM(ai.qty)     AS quantity
FROM    all_ingredients ai
JOIN    pizza_toppings  pt USING (topping_id)
GROUP BY pt.topping_name
ORDER BY pt.topping_name;