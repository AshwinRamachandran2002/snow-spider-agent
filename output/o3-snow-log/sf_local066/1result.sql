/* Summarise total quantity of every ingredient that actually ended up
   on customers’ pizzas (i.e., only orders that were delivered).       */

WITH delivered AS (     -- orders that were successfully delivered
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS
    WHERE NVL(TRIM("cancellation"),'') = ''
      AND NVL(TRIM("pickup_time"),'')  <> ''
),

customer_pizzas AS (    -- pizzas in those delivered orders
    SELECT  c."order_id",
            c."pizza_id",
            NVL(c."exclusions",'') AS "exclusions",
            NVL(c."extras",'')     AS "extras"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS c
    JOIN delivered d
      ON c."order_id" = d."order_id"
),

recipe_toppings AS (    -- explode recipe toppings once per pizza_id
    SELECT  pr."pizza_id",
            rt.value::NUMBER AS "topping_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_RECIPES pr,
         LATERAL FLATTEN( input => SPLIT( REPLACE(pr."toppings",' ',''), ',' ) ) rt
    WHERE rt.value <> ''
),

base_toppings AS (      -- map recipe toppings to every ordered pizza
    SELECT  cp."order_id",
            cp."exclusions",
            cp."extras",
            rt."topping_id"
    FROM customer_pizzas cp
    JOIN recipe_toppings rt
      ON cp."pizza_id" = rt."pizza_id"
),

exclusions_expanded AS (    -- explode exclusions list per order
    SELECT  cp."order_id",
            ex.value::NUMBER AS "topping_id"
    FROM customer_pizzas cp,
         LATERAL FLATTEN( input => SPLIT( REPLACE(cp."exclusions",' ',''), ',' ) ) ex
    WHERE cp."exclusions" <> ''
      AND ex.value <> ''
),

filtered_base AS (      -- keep base toppings that were NOT excluded
    SELECT  bt."order_id",
            bt."topping_id"
    FROM   base_toppings bt
    LEFT  JOIN exclusions_expanded ee
           ON bt."order_id"  = ee."order_id"
          AND bt."topping_id" = ee."topping_id"
    WHERE  ee."topping_id" IS NULL
),

extra_toppings AS (     -- explode any extra toppings added
    SELECT  cp."order_id",
            et.value::NUMBER AS "topping_id"
    FROM   customer_pizzas cp,
           LATERAL FLATTEN( input => SPLIT( REPLACE(cp."extras",' ',''), ',' ) ) et
    WHERE  cp."extras" <> ''
      AND  et.value <> ''
),

all_toppings AS (       -- combine base (post-exclusion) and extras
    SELECT "topping_id" FROM filtered_base
    UNION ALL
    SELECT "topping_id" FROM extra_toppings
)

SELECT  pt."topping_name" AS name,
        COUNT(*)          AS quantity
FROM    all_toppings at
JOIN    MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
      ON pt."topping_id" = at."topping_id"
GROUP BY pt."topping_name"
ORDER BY quantity DESC NULLS LAST;