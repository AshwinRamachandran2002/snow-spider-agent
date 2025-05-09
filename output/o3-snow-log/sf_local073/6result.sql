/* ------------------------------------------------------------------
   Build, for every pizza in every order, the final list of toppings
-------------------------------------------------------------------*/
WITH /*-------------------------------------------------------------
      1. give each pizza-line in an order its own row_id
------------------------------------------------------------------*/
order_rows AS (         
    SELECT 
        "order_id",
        ROW_NUMBER() OVER (PARTITION BY "order_id" 
                           ORDER BY "pizza_id", "customer_id", "order_time") AS row_id,
        "customer_id",
        /* only pizza_id = 1 is Meatlovers, all others become 2       */
        CASE WHEN "pizza_id" = 1 THEN 1 ELSE 2 END                            AS pizza_id,
        "exclusions",
        "extras"
    FROM MODERN_DATA.MODERN_DATA."PIZZA_CLEAN_CUSTOMER_ORDERS"
),

/*------------------------------------------------------------------
   2. collect exclusions and extras for each (order_id , row_id)
------------------------------------------------------------------*/
exclusions AS (
    SELECT 
        "order_id",
        "row_id",
        ARRAY_AGG("exclusions")                      AS excl_ids
    FROM MODERN_DATA.MODERN_DATA."PIZZA_GET_EXCLUSIONS"
    GROUP BY "order_id","row_id"
),
extras AS (
    SELECT
        "order_id",
        "row_id",
        ARRAY_AGG("extras")                          AS extra_ids
    FROM MODERN_DATA.MODERN_DATA."PIZZA_GET_EXTRAS"
    GROUP BY "order_id","row_id"
),

/*------------------------------------------------------------------
   3. explode every pizza recipe into (pizza_id , topping_id)
------------------------------------------------------------------*/
recipe_expanded AS (
    SELECT 
        pr."pizza_id",
        TO_NUMBER(TRIM(f.value))                     AS topping_id
    FROM MODERN_DATA.MODERN_DATA."PIZZA_RECIPES" pr,
         LATERAL FLATTEN( INPUT => SPLIT(TRIM(pr."toppings"), ',') ) f
),
standard_toppings AS (
    SELECT 
        "pizza_id",
        ARRAY_AGG(DISTINCT topping_id)               AS std_ids
    FROM recipe_expanded
    GROUP BY "pizza_id"
),

/*------------------------------------------------------------------
   4. join standard, exclusions, extras for every pizza row
------------------------------------------------------------------*/
orders_plus AS (
    SELECT
        o.row_id,
        o."order_id",
        o."customer_id",
        o.pizza_id,
        COALESCE(st.std_ids , ARRAY_CONSTRUCT())     AS std_ids,
        COALESCE(e.excl_ids, ARRAY_CONSTRUCT())      AS excl_ids,
        COALESCE(x.extra_ids,ARRAY_CONSTRUCT())      AS extra_ids
    FROM order_rows o
    LEFT JOIN standard_toppings st ON st."pizza_id" = o.pizza_id
    LEFT JOIN exclusions        e  ON e."order_id"  = o."order_id" AND e."row_id" = o.row_id
    LEFT JOIN extras            x  ON x."order_id"  = o."order_id" AND x."row_id" = o.row_id
),

/*------------------------------------------------------------------
   5. build final topping-id list (standard minus exclusions + extras)
------------------------------------------------------------------*/
final_ids AS (        
    SELECT
        row_id,
        "order_id",
        "customer_id",
        pizza_id,
        ARRAY_AGG(topping_id)                        AS all_ids
    FROM (
          /* keep every standard topping not excluded */
          SELECT 
              op.row_id,
              op."order_id",
              op."customer_id",
              op.pizza_id,
              TO_NUMBER(std.value)                   AS topping_id
          FROM orders_plus op,
               LATERAL FLATTEN( INPUT => op.std_ids ) std
          WHERE NOT ARRAY_CONTAINS(op.excl_ids , TO_VARIANT( TO_NUMBER(std.value) ))

          UNION ALL

          /* and add every extra topping (allow duplicates) */
          SELECT 
              op.row_id,
              op."order_id",
              op."customer_id",
              op.pizza_id,
              TO_NUMBER(ext.value)                   AS topping_id
          FROM orders_plus op,
               LATERAL FLATTEN( INPUT => op.extra_ids ) ext
    ) t
    GROUP BY row_id, "order_id", "customer_id", pizza_id
),

/*------------------------------------------------------------------
   6. translate ids to names, counting duplicates
------------------------------------------------------------------*/
topping_counts AS (
    SELECT
        f.row_id,
        f."order_id",
        f."customer_id",
        f.pizza_id,
        pt."topping_name",
        COUNT(*)                                     AS cnt
    FROM final_ids f,
         LATERAL FLATTEN( INPUT => f.all_ids ) a
    JOIN MODERN_DATA.MODERN_DATA."PIZZA_TOPPINGS" pt
         ON pt."topping_id" = a.value
    GROUP BY f.row_id, f."order_id", f."customer_id", f.pizza_id, pt."topping_name"
),

/*------------------------------------------------------------------
   7. combine names alphabetically, prefixing repeats with “2x”
------------------------------------------------------------------*/
topping_strings AS (
    SELECT
        row_id,
        "order_id",
        "customer_id",
        pizza_id,
        ARRAY_AGG(
            CASE WHEN cnt > 1 
                 THEN cnt || 'x ' || "topping_name"
                 ELSE            "topping_name"
            END
        ) WITHIN GROUP (ORDER BY "topping_name")     AS topping_arr
    FROM topping_counts
    GROUP BY row_id, "order_id", "customer_id", pizza_id
),

/*------------------------------------------------------------------
   8. prepend the pizza name and form the final ingredient string
------------------------------------------------------------------*/
named AS (
    SELECT
        ts.row_id,
        ts."order_id",
        ts."customer_id",
        pn."pizza_name",
        pn."pizza_name" || ': ' || ARRAY_TO_STRING(ts.topping_arr, ', ') AS ingredients
    FROM topping_strings ts
    JOIN MODERN_DATA.MODERN_DATA."PIZZA_NAMES" pn
         ON pn."pizza_id" = ts.pizza_id
)

/*------------------------------------------------------------------
   FINAL OUTPUT
------------------------------------------------------------------*/
SELECT
    row_id        AS "row_id",
    "order_id"    AS "order_id",
    "customer_id" AS "customer_id",
    "pizza_name"  AS "pizza_name",
    ingredients   AS "ingredients"
FROM named
ORDER BY row_id;