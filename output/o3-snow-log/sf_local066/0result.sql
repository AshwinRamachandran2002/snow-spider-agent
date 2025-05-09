/* 1. take only pizzas that were actually delivered (not cancelled and with a real pickup time)
   2. start from the standard recipe for every pizza
   3. remove any toppings the customer excluded
   4. add any extras the customer requested (extras can appear more than once)
   5. aggregate everything to work out how many of each topping we finally used           */

WITH delivered AS (   -- pizzas that reached the customer
    SELECT  cco.*
    FROM    MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS  cco
    JOIN    MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS    cro
           ON cco."order_id" = cro."order_id"
    WHERE   cro."cancellation" = ''
      AND   cro."pickup_time"  <> ''
),

recipe_toppings AS (  -- add the basic recipe for each pizza
    SELECT  d."order_id",
            d."pizza_id",
            d."exclusions",
            d."extras",
            pr."toppings"           AS recipe_toppings
    FROM    delivered d
    JOIN    MODERN_DATA.MODERN_DATA.PIZZA_RECIPES pr
           ON d."pizza_id" = pr."pizza_id"
),

base_toppings AS (    -- explode recipe into one row per topping
    SELECT  r."order_id",
            r."pizza_id",
            VALUE::NUMBER           AS topping_id
    FROM    recipe_toppings r,
            LATERAL FLATTEN(
                   INPUT => SPLIT( REGEXP_REPLACE(r.recipe_toppings,'\\s',''), ',' )
            )
),

exclusion_toppings AS (  -- explode any exclusions
    SELECT  r."order_id",
            r."pizza_id",
            VALUE::NUMBER           AS topping_id
    FROM    recipe_toppings r,
            LATERAL FLATTEN(
                   INPUT => CASE
                               WHEN REGEXP_REPLACE(COALESCE(r."exclusions",''),'\\s','') = ''
                               THEN NULL
                               ELSE SPLIT( REGEXP_REPLACE(r."exclusions",'\\s',''), ',' )
                            END
            )
    WHERE   VALUE IS NOT NULL
),

extras_toppings AS (     -- explode any extras (can repeat)
    SELECT  r."order_id",
            r."pizza_id",
            VALUE::NUMBER           AS topping_id
    FROM    recipe_toppings r,
            LATERAL FLATTEN(
                   INPUT => CASE
                               WHEN REGEXP_REPLACE(COALESCE(r."extras",''),'\\s','') = ''
                               THEN NULL
                               ELSE SPLIT( REGEXP_REPLACE(r."extras",'\\s',''), ',' )
                            END
            )
    WHERE   VALUE IS NOT NULL
),

base_after_exclusions AS (   -- keep base toppings that were NOT excluded
    SELECT  b.*
    FROM    base_toppings b
    LEFT JOIN exclusion_toppings e
           ON  b."order_id" = e."order_id"
           AND b."pizza_id" = e."pizza_id"
           AND b.topping_id = e.topping_id
    WHERE   e.topping_id IS NULL
),

all_toppings AS (   -- everything we finally used:   (recipe – exclusions)  ∪  extras
    SELECT topping_id FROM base_after_exclusions
    UNION ALL
    SELECT topping_id FROM extras_toppings
)

SELECT  pt."topping_name"        AS "ingredient_name",
        COUNT(*)                 AS "quantity"
FROM    all_toppings at
JOIN    MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
       ON at.topping_id = pt."topping_id"
GROUP BY pt."topping_name"
ORDER BY "quantity" DESC NULLS LAST;