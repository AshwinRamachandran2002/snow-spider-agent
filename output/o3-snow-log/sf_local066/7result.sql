/* 1. find successfully delivered orders */
WITH delivered_orders AS (
    SELECT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS
    WHERE COALESCE("cancellation", '') = ''
      AND COALESCE("pickup_time", '') <> ''
),

/* 2. every pizza that was part of a delivered order                     */
/*    (keep duplicates – they represent separate pizzas)                 */
pizza_orders AS (
    SELECT cco."order_id",
           cco."pizza_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS cco
    JOIN delivered_orders d
      ON cco."order_id" = d."order_id"
),

/* 3. explode each pizza’s default recipe into one row per topping id     */
pizza_default_toppings AS (
    SELECT  po."order_id",
            TRIM(t.value)::NUMBER AS topping_id
    FROM    pizza_orders                    po
    JOIN    MODERN_DATA.MODERN_DATA.PIZZA_RECIPES pr
           ON po."pizza_id" = pr."pizza_id",
           LATERAL FLATTEN( input => SPLIT(pr."toppings", ',') ) t
),

/* 4. toppings the customer removed                                       */
exclusions AS (
    SELECT "order_id",
           "exclusions"::NUMBER AS topping_id
    FROM   MODERN_DATA.MODERN_DATA.PIZZA_GET_EXCLUSIONS
    WHERE  "order_id" IN (SELECT "order_id" FROM delivered_orders)
),

/* 5. extra toppings the customer added                                   */
extras AS (
    SELECT "order_id",
           "extras"::NUMBER AS topping_id
    FROM   MODERN_DATA.MODERN_DATA.PIZZA_GET_EXTRAS
    WHERE  "order_id" IN (SELECT "order_id" FROM delivered_orders)
),

/* 6. final toppings used for each delivered pizza                        */
adjusted_toppings AS (
    /* default toppings minus what was excluded */
    SELECT  pd."order_id",
            pd.topping_id
    FROM    pizza_default_toppings pd
    LEFT JOIN exclusions e
           ON  pd."order_id"  = e."order_id"
          AND pd.topping_id   = e.topping_id
    WHERE   e.topping_id IS NULL

    UNION ALL

    /* plus any extras                                                     */
    SELECT  "order_id",
            topping_id
    FROM    extras
)

/* 7. aggregate the ingredient usage                                      */
SELECT  pt."topping_name"  AS "ingredient",
        COUNT(*)           AS "quantity"
FROM    adjusted_toppings   at
JOIN    MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
      ON at.topping_id = pt."topping_id"
GROUP BY pt."topping_name"
ORDER BY "quantity" DESC NULLS LAST;