WITH orders AS (
    SELECT
      ROW_NUMBER() OVER (ORDER BY pcco."order_time", pcco."order_id", pcco."pizza_id") AS "row_id",
      pcco."order_id",
      pcco."customer_id",
      CASE WHEN pn."pizza_name" = 'Meatlovers' THEN 1 ELSE 2 END AS "pizza_id",
      pn."pizza_name",
      SPLIT(TRIM(REPLACE(pr."toppings", ' ', '')), ',') AS "standard_toppings",
      SPLIT(NULLIF(TRIM(REPLACE(pcco."exclusions", ' ', '')), ''), ',') AS "exclusions",
      SPLIT(NULLIF(TRIM(REPLACE(pcco."extras", ' ', '')), ''), ',') AS "extras"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS pcco
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES pn ON pcco."pizza_id" = pn."pizza_id"
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_RECIPES pr ON pn."pizza_id" = pr."pizza_id"
),
standard_toppings AS (
    SELECT
      o."row_id",
      st.value::VARCHAR AS "topping_id"
    FROM orders o
    LEFT JOIN LATERAL FLATTEN(input => o."standard_toppings") st
),
exclusions AS (
    SELECT
      o."row_id",
      ex.value::VARCHAR AS "topping_id"
    FROM orders o
    LEFT JOIN LATERAL FLATTEN(input => o."exclusions") ex
),
extras AS (
    SELECT
      o."row_id",
      ex.value::VARCHAR AS "topping_id"
    FROM orders o
    LEFT JOIN LATERAL FLATTEN(input => o."extras") ex
),
standard_without_exclusions AS (
    SELECT st.*
    FROM standard_toppings st
    LEFT JOIN exclusions ex ON st."row_id" = ex."row_id" AND st."topping_id" = ex."topping_id"
    WHERE ex."topping_id" IS NULL
),
all_toppings AS (
    SELECT "row_id", "topping_id" FROM standard_without_exclusions
    UNION ALL
    SELECT "row_id", "topping_id" FROM extras WHERE "topping_id" IS NOT NULL
),
topping_counts AS (
    SELECT 
      at."row_id",
      at."topping_id",
      COUNT(*) AS "count"
    FROM all_toppings at
    GROUP BY at."row_id", at."topping_id"
),
toppings_with_names AS (
    SELECT
      tc."row_id",
      tt."topping_name",
      tc."count"
    FROM topping_counts tc
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS tt ON tt."topping_id" = tc."topping_id"::INT
),
final_ingredients AS (
    SELECT
      "row_id",
      LISTAGG(
        CASE WHEN "count" > 1 THEN CONCAT('2x ', "topping_name") ELSE "topping_name" END,
        ', '
      ) WITHIN GROUP (ORDER BY "topping_name") AS "ingredients_list"
    FROM toppings_with_names
    GROUP BY "row_id"
)
SELECT
  o."row_id",
  o."order_id",
  o."customer_id",
  o."pizza_id",
  o."pizza_name",
  CONCAT(o."pizza_name", ': ', fi."ingredients_list") AS "final_ingredients"
FROM orders o
LEFT JOIN final_ingredients fi ON o."row_id" = fi."row_id"
ORDER BY o."row_id";