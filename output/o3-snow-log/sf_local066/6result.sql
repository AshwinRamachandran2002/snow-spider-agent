/* Total quantity of each ingredient actually used in pizzas that were delivered */
WITH delivered_orders AS (          /* 1. Orders successfully delivered */
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_RUNNER_ORDERS
    WHERE TRIM("cancellation") = ''
),

order_pizzas AS (                   /* 2. Pizzas in those delivered orders */
    SELECT  o."order_id",
            o."pizza_id",
            o."exclusions",
            o."extras"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS o
    JOIN delivered_orders d
      ON d."order_id" = o."order_id"
),

recipe_toppings AS (                /* 3. Base-recipe toppings */
    SELECT  op."order_id",
            op."pizza_id",
            f.value::NUMBER AS "topping_id"
    FROM order_pizzas op
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_RECIPES r
      ON r."pizza_id" = op."pizza_id"
    ,     LATERAL FLATTEN( input => SPLIT(REPLACE(r."toppings",' ',''), ',') ) f
),

extra_toppings AS (                 /* 4. Extra toppings requested */
    SELECT  op."order_id",
            op."pizza_id",
            f.value::NUMBER AS "topping_id"
    FROM order_pizzas op
    ,     LATERAL FLATTEN(
              input => CASE
                          WHEN TRIM(op."extras") = '' 
                               THEN ARRAY_CONSTRUCT() 
                          ELSE SPLIT(REPLACE(op."extras",' ',''), ',')
                       END
          ) f
),

all_toppings AS (                   /* 5. All toppings (recipe + extras) */
    SELECT * FROM recipe_toppings
    UNION ALL
    SELECT * FROM extra_toppings
),

excluded_toppings AS (              /* 6. Toppings the customer excluded */
    SELECT  op."order_id",
            op."pizza_id",
            f.value::NUMBER AS "topping_id"
    FROM order_pizzas op
    ,     LATERAL FLATTEN(
              input => CASE
                          WHEN TRIM(op."exclusions") = '' 
                               THEN ARRAY_CONSTRUCT() 
                          ELSE SPLIT(REPLACE(op."exclusions",' ',''), ',')
                       END
          ) f
),

final_toppings AS (                 /* 7. Actual toppings used = all – exclusions */
    SELECT  at."order_id",
            at."pizza_id",
            at."topping_id"
    FROM all_toppings at
    LEFT JOIN excluded_toppings et
           ON  et."order_id"   = at."order_id"
           AND et."pizza_id"   = at."pizza_id"
           AND et."topping_id" = at."topping_id"
    WHERE et."topping_id" IS NULL
)

/* 8. Aggregate ingredient usage */
SELECT  pt."topping_name" AS ingredient_name,
        COUNT(*)          AS quantity
FROM final_toppings ft
JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
  ON pt."topping_id" = ft."topping_id"
GROUP BY pt."topping_name"
ORDER BY quantity DESC NULLS LAST;