/*-----------------------------------------------------------
   Build the requested pizza-order listing
-----------------------------------------------------------*/
WITH orders AS (      /* base customer orders */
    SELECT
        ROW_NUMBER() OVER (ORDER BY "order_id",
                                   "customer_id",
                                   "pizza_id",
                                   "order_time")              AS row_id,
        "order_id"                                            AS order_id,
        "customer_id"                                         AS customer_id,
        "pizza_id"                                            AS pizza_id,
        TRIM(COALESCE("exclusions", ''))                      AS exclusions,
        TRIM(COALESCE("extras",     ''))                      AS extras,
        "order_time"                                          AS order_time
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS
),

/* 1) standard toppings from the recipe ---------------------*/
standard AS (
    SELECT
        o.row_id,
        o.order_id,
        o.customer_id,
        o.pizza_id,
        f.value::NUMBER                                       AS topping_id,
        1                                                     AS cnt          /* +1 */
    FROM orders o
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_RECIPES r
          ON r."pizza_id" = o.pizza_id
    CROSS JOIN LATERAL FLATTEN(
          INPUT => SPLIT(REPLACE(r."toppings", ' ', ''), ',')
    ) f
),

/* 2) toppings to be excluded -------------------------------*/
exclusions AS (
    SELECT
        o.row_id,
        o.order_id,
        o.customer_id,
        o.pizza_id,
        f.value::NUMBER                                       AS topping_id,
        -1                                                    AS cnt          /* −1 */
    FROM orders o
    CROSS JOIN LATERAL FLATTEN(
          INPUT => SPLIT(REPLACE(o.exclusions, ' ', ''), ',')
    ) f
    WHERE o.exclusions <> ''
),

/* 3) extra toppings to be added ----------------------------*/
extras AS (
    SELECT
        o.row_id,
        o.order_id,
        o.customer_id,
        o.pizza_id,
        f.value::NUMBER                                       AS topping_id,
        1                                                     AS cnt          /* +1 */
    FROM orders o
    CROSS JOIN LATERAL FLATTEN(
          INPUT => SPLIT(REPLACE(o.extras, ' ', ''), ',')
    ) f
    WHERE o.extras <> ''
),

/* Combine counts for each topping --------------------------*/
topping_totals AS (
    SELECT
        row_id,
        order_id,
        customer_id,
        pizza_id,
        topping_id,
        SUM(cnt)                                              AS final_cnt
    FROM (
        SELECT * FROM standard
        UNION ALL
        SELECT * FROM exclusions
        UNION ALL
        SELECT * FROM extras
    )
    GROUP BY row_id, order_id, customer_id, pizza_id, topping_id
    HAVING SUM(cnt) > 0
),

/* Convert topping_id → name; prefix “2x” when repeated -----*/
topping_names AS (
    SELECT
        t.row_id,
        t.order_id,
        t.customer_id,
        t.pizza_id,
        CASE
            WHEN t.final_cnt > 1
                 THEN CONCAT(t.final_cnt::STRING, 'x', p."topping_name")
            ELSE p."topping_name"
        END                                                   AS topping_display
    FROM topping_totals t
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS p
          ON p."topping_id" = t.topping_id
),

/* Build alphabetically ordered, comma-separated ingredient list */
ingredients_per_order AS (
    SELECT
        row_id,
        order_id,
        customer_id,
        pizza_id,
        LISTAGG(topping_display, ', ')
            WITHIN GROUP (ORDER BY topping_display)           AS ingredient_list
    FROM topping_names
    GROUP BY row_id, order_id, customer_id, pizza_id
),

/* Attach pizza name (id 1 = Meatlovers; others treated as id 2) */
pizza_info AS (
    SELECT
        o.row_id,
        o.order_id,
        o.customer_id,
        CASE WHEN o.pizza_id = 1 THEN 1 ELSE 2 END            AS final_pizza_id,
        COALESCE(pn."pizza_name", 'Vegetarian')               AS pizza_name,
        i.ingredient_list
    FROM orders o
    JOIN ingredients_per_order i
          ON i.row_id = o.row_id
    LEFT JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES pn
          ON pn."pizza_id" = o.pizza_id
)

/*-----------------------  Final result ----------------------*/
SELECT
    row_id                                    AS "row_id",
    order_id                                  AS "order_id",
    customer_id                               AS "customer_id",
    pizza_name                                AS "pizza_name",
    CONCAT(pizza_name, ': ', ingredient_list) AS "final_ingredients"
FROM pizza_info
ORDER BY row_id;