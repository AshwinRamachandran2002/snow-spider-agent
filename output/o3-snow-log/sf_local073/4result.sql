/*-----------------------------------------------------------------
   Build the final ingredient list for every pizza order
-----------------------------------------------------------------*/
WITH base_orders AS (        /* create a row_id and normalise pizza_id */
    SELECT
        ROW_NUMBER() OVER (ORDER BY "order_time", "order_id")              AS "ROW_ID",
        "order_id"                                                        AS "ORDER_ID",
        "customer_id"                                                     AS "CUSTOMER_ID",
        CASE WHEN "pizza_id" = 1 THEN 1 ELSE 2 END                        AS "PIZZA_ID_FINAL",
        TRIM("exclusions")                                                AS "EXCLUSIONS",
        TRIM("extras")                                                    AS "EXTRAS"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS
),

orders_recipes AS (          /* attach the recipe toppings for each pizza */
    SELECT
        b.*,
        r."toppings"                                                    AS "RECIPE_TOPPINGS"
    FROM base_orders b
    LEFT JOIN MODERN_DATA.MODERN_DATA.PIZZA_RECIPES r
           ON b."PIZZA_ID_FINAL" = r."pizza_id"
),

/*-----------------------------------------------------------------
   explode standard toppings, extras, and exclusions
-----------------------------------------------------------------*/
std_tops AS (
    SELECT  o."ROW_ID", o."ORDER_ID", o."CUSTOMER_ID", o."PIZZA_ID_FINAL",
            TO_NUMBER(TRIM(f.value))                                     AS "TOPPING_ID",
            1                                                            AS "CNT"
    FROM orders_recipes o,
         LATERAL FLATTEN(INPUT => SPLIT(o."RECIPE_TOPPINGS", ',')) f
    WHERE TRIM(f.value) <> ''
),

ext_tops AS (
    SELECT  o."ROW_ID", o."ORDER_ID", o."CUSTOMER_ID", o."PIZZA_ID_FINAL",
            TO_NUMBER(TRIM(f.value))                                     AS "TOPPING_ID",
            1                                                            AS "CNT"
    FROM orders_recipes o,
         LATERAL FLATTEN(INPUT => SPLIT(o."EXTRAS", ',')) f
    WHERE o."EXTRAS" IS NOT NULL
      AND TRIM(o."EXTRAS") <> ''
      AND TRIM(f.value) <> ''
),

exc_tops AS (                 /* toppings to be excluded */
    SELECT  o."ROW_ID", o."ORDER_ID",
            TO_NUMBER(TRIM(f.value))                                     AS "TOPPING_ID"
    FROM orders_recipes o,
         LATERAL FLATTEN(INPUT => SPLIT(o."EXCLUSIONS", ',')) f
    WHERE o."EXCLUSIONS" IS NOT NULL
      AND TRIM(o."EXCLUSIONS") <> ''
      AND TRIM(f.value) <> ''
),

/*-----------------------------------------------------------------
   combine std + extras, remove exclusions, count duplicates
-----------------------------------------------------------------*/
combined AS (
    SELECT * FROM std_tops
    UNION ALL
    SELECT * FROM ext_tops
),

kept AS (
    SELECT  c."ROW_ID",
            c."ORDER_ID",
            c."CUSTOMER_ID",
            c."PIZZA_ID_FINAL",
            c."TOPPING_ID",
            SUM(c."CNT")                                                 AS "TOTAL_CNT"
    FROM combined c
    LEFT JOIN exc_tops e
           ON  c."ROW_ID"     = e."ROW_ID"
           AND c."ORDER_ID"   = e."ORDER_ID"
           AND c."TOPPING_ID" = e."TOPPING_ID"
    WHERE e."TOPPING_ID" IS NULL                                         -- drop excluded toppings
    GROUP BY c."ROW_ID", c."ORDER_ID", c."CUSTOMER_ID",
             c."PIZZA_ID_FINAL", c."TOPPING_ID"
),

/*-----------------------------------------------------------------
   translate topping_id → topping_name
-----------------------------------------------------------------*/
named AS (
    SELECT
        k."ROW_ID",
        k."ORDER_ID",
        k."CUSTOMER_ID",
        k."PIZZA_ID_FINAL",
        t."topping_name"                                                 AS "TOPPING_NAME",
        k."TOTAL_CNT"
    FROM kept k
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS t
          ON k."TOPPING_ID" = t."topping_id"
),

/*-----------------------------------------------------------------
   assemble the ordered ingredient list
-----------------------------------------------------------------*/
agg AS (
    SELECT
        "ROW_ID",
        "ORDER_ID",
        "CUSTOMER_ID",
        "PIZZA_ID_FINAL",
        LISTAGG(
            CASE
                WHEN "TOTAL_CNT" > 1
                    THEN "TOTAL_CNT" || 'x' || "TOPPING_NAME"
                ELSE "TOPPING_NAME"
            END,
            ', '
        ) WITHIN GROUP (ORDER BY LOWER("TOPPING_NAME"))                  AS "TOPPING_LIST"
    FROM named
    GROUP BY "ROW_ID", "ORDER_ID", "CUSTOMER_ID", "PIZZA_ID_FINAL"
),

/*-----------------------------------------------------------------
   attach pizza names & build final string
-----------------------------------------------------------------*/
final AS (
    SELECT
        a."ROW_ID",
        a."ORDER_ID",
        a."CUSTOMER_ID",
        p."pizza_name"                                                   AS "PIZZA_NAME",
        p."pizza_name" || ': ' || a."TOPPING_LIST"                       AS "FINAL_INGREDIENTS"
    FROM agg a
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES p
      ON a."PIZZA_ID_FINAL" = p."pizza_id"
)

/*-----------------------------------------------------------------
   required output
-----------------------------------------------------------------*/
SELECT
    "ROW_ID",
    "ORDER_ID",
    "CUSTOMER_ID",
    "PIZZA_NAME",
    "FINAL_INGREDIENTS"
FROM final
ORDER BY "ROW_ID";