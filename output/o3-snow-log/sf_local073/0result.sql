WITH base_orders AS (   /* one row per pizza order */
    SELECT 
        ROW_NUMBER() OVER (ORDER BY "order_id", "order_time")  AS ROW_ID,
        "order_id"                                             AS ORDER_ID,
        "customer_id"                                          AS CUSTOMER_ID,
        CASE WHEN "pizza_id" = 1 THEN 1 ELSE 2 END             AS PIZZA_ID,      -- enforce rule
        COALESCE(TRIM("exclusions"), '')                       AS EXCLUSIONS,
        COALESCE(TRIM("extras"), '')                           AS EXTRAS
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS
),

/* standard toppings from each recipe, one row per topping */
recipe_toppings AS (
    SELECT  
        r."pizza_id"                                           AS PIZZA_ID,
        TRIM(f.value)::NUMBER                                  AS TOPPING_ID
    FROM MODERN_DATA.MODERN_DATA.PIZZA_RECIPES r,
         LATERAL FLATTEN( INPUT => SPLIT(r."toppings", ',') ) f
),

/* explode standard, exclusions and extras into separate rows */
standard AS (
    SELECT o.ROW_ID, rt.TOPPING_ID
    FROM  base_orders o
    JOIN  recipe_toppings rt 
          ON rt.PIZZA_ID = o.PIZZA_ID
),
exclusions AS (
    SELECT o.ROW_ID, TRIM(f.value)::NUMBER AS TOPPING_ID
    FROM  base_orders o,
          LATERAL FLATTEN(
              INPUT => CASE 
                           WHEN o.EXCLUSIONS IN ('', 'null') 
                           THEN ARRAY_CONSTRUCT() 
                           ELSE SPLIT(o.EXCLUSIONS, ',') 
                       END
          ) f
    WHERE TRIM(f.value) <> ''
),
extras AS (
    SELECT o.ROW_ID, TRIM(f.value)::NUMBER AS TOPPING_ID
    FROM  base_orders o,
          LATERAL FLATTEN(
              INPUT => CASE 
                           WHEN o.EXTRAS IN ('', 'null') 
                           THEN ARRAY_CONSTRUCT() 
                           ELSE SPLIT(o.EXTRAS, ',') 
                       END
          ) f
    WHERE TRIM(f.value) <> ''
),

/* remove excluded toppings from the standard list */
valid_standard AS (
    SELECT s.*
    FROM   standard s
    LEFT   JOIN exclusions e
           ON  s.ROW_ID     = e.ROW_ID
          AND s.TOPPING_ID  = e.TOPPING_ID
    WHERE  e.TOPPING_ID IS NULL
),

/* union the remaining standard toppings with any extras (duplicates allowed) */
all_kept AS (
    SELECT ROW_ID, TOPPING_ID FROM valid_standard
    UNION ALL
    SELECT ROW_ID, TOPPING_ID FROM extras
),

/* count occurrences of each topping for every order */
topping_counts AS (
    SELECT ROW_ID, TOPPING_ID, COUNT(*) AS CNT
    FROM   all_kept
    GROUP  BY ROW_ID, TOPPING_ID
),

/* build the final, alphabetically-sorted ingredient string */
final_ingredients AS (
    SELECT 
        tc.ROW_ID,
        LISTAGG(
            CASE WHEN tc.CNT > 1 
                 THEN tc.CNT || 'x ' || pt."topping_name"
                 ELSE               pt."topping_name"
            END,
            ', '
        ) WITHIN GROUP (ORDER BY pt."topping_name") AS INGREDIENT_LIST
    FROM   topping_counts tc
    JOIN   MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
           ON pt."topping_id" = tc.TOPPING_ID
    GROUP  BY tc.ROW_ID
)

/* produce required output */
SELECT  
    bo.ROW_ID,
    bo.ORDER_ID,
    bo.CUSTOMER_ID,
    pn."pizza_name",
    pn."pizza_name" || ': ' || fi.INGREDIENT_LIST AS FINAL_INGREDIENTS
FROM    base_orders bo
JOIN    MODERN_DATA.MODERN_DATA.PIZZA_NAMES pn
        ON pn."pizza_id" = bo.PIZZA_ID
JOIN    final_ingredients fi
        ON fi.ROW_ID = bo.ROW_ID
ORDER BY bo.ROW_ID;