WITH delivered_orders AS (               -- only the orders that were actually delivered
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_RUNNER_ORDERS
    WHERE COALESCE(TRIM("cancellation"),'') = ''
      AND TRIM("pickup_time") <> ''
),

customer_pizzas AS (                     -- every pizza in those delivered orders
    SELECT c.*
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS c
    JOIN delivered_orders d  ON c."order_id" = d."order_id"
),

base_toppings AS (                       -- recipe (base-topping list) for every pizza type
    SELECT 
        "pizza_id",
        SPLIT(REPLACE("toppings",' ',''), ',') AS topping_list
    FROM MODERN_DATA.MODERN_DATA.PIZZA_RECIPES
),

customer_with_recipe AS (                -- bring recipe together with individual order details
    SELECT 
        cp."order_id",
        cp."pizza_id",
        cp."exclusions",
        cp."extras",
        bt.topping_list
    FROM customer_pizzas cp
    JOIN base_toppings bt ON cp."pizza_id" = bt."pizza_id"
),

recipe_toppings AS (                     -- explode the recipe toppings to one row each
    SELECT
        cwr."order_id",
        cwr."pizza_id",
        value::NUMBER AS topping_id,
        cwr."exclusions",
        cwr."extras"
    FROM customer_with_recipe cwr,
         LATERAL FLATTEN( input => cwr.topping_list )
),

exclusion_toppings AS (                  -- explode any exclusions
    SELECT
        cwr."order_id",
        cwr."pizza_id",
        value::NUMBER AS exclusion_id
    FROM customer_with_recipe cwr,
         LATERAL FLATTEN(
             input => IFF( TRIM(cwr."exclusions") = '',
                           NULL,
                           SPLIT(REPLACE(cwr."exclusions",' ',''), ',') )
         )
),

filtered_recipe AS (                     -- keep recipe toppings that are NOT excluded
    SELECT
        rt."order_id",
        rt."pizza_id",
        rt.topping_id
    FROM recipe_toppings rt
    LEFT JOIN exclusion_toppings et
           ON  rt."order_id" = et."order_id"
           AND rt."pizza_id" = et."pizza_id"
           AND rt.topping_id = et.exclusion_id
    WHERE et.exclusion_id IS NULL
),

extra_toppings AS (                      -- explode any extras
    SELECT
        cwr."order_id",
        cwr."pizza_id",
        value::NUMBER AS topping_id
    FROM customer_with_recipe cwr,
         LATERAL FLATTEN(
             input => IFF( TRIM(cwr."extras") = '',
                           NULL,
                           SPLIT(REPLACE(cwr."extras",' ',''), ',') )
         )
),

all_used_toppings AS (                   -- union recipe-minus-exclusions with extras
    SELECT * FROM filtered_recipe
    UNION ALL
    SELECT * FROM extra_toppings
)

SELECT
    pt."topping_name"  AS "ingredient_name",
    COUNT(*)           AS "quantity"
FROM all_used_toppings aut
JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
     ON aut.topping_id = pt."topping_id"
GROUP BY pt."topping_name"
ORDER BY "quantity" DESC NULLS LAST;