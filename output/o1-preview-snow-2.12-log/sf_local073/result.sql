WITH orders_with_row_id AS (
  SELECT
    ROW_NUMBER() OVER (
      ORDER BY "order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time"
    ) AS "row_id",
    o.*
  FROM
    "MODERN_DATA"."MODERN_DATA"."PIZZA_CLEAN_CUSTOMER_ORDERS" o
),
standard_toppings AS (
  SELECT
    o."row_id",
    TRY_TO_NUMBER(TRIM(t.value)) AS "topping_id"
  FROM
    orders_with_row_id o
    JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_RECIPES" r ON o."pizza_id" = r."pizza_id",
    LATERAL FLATTEN(input => SPLIT(r."toppings", ',')) t
  WHERE
    TRY_TO_NUMBER(TRIM(t.value)) IS NOT NULL
),
exclusions AS (
  SELECT
    o."row_id",
    TRY_TO_NUMBER(TRIM(e.value)) AS "topping_id"
  FROM
    orders_with_row_id o,
    LATERAL FLATTEN(input => SPLIT(o."exclusions", ',')) e
  WHERE
    o."exclusions" IS NOT NULL
    AND TRY_TO_NUMBER(TRIM(e.value)) IS NOT NULL
),
extras AS (
  SELECT
    o."row_id",
    TRY_TO_NUMBER(TRIM(e.value)) AS "topping_id"
  FROM
    orders_with_row_id o,
    LATERAL FLATTEN(input => SPLIT(o."extras", ',')) e
  WHERE
    o."extras" IS NOT NULL
    AND TRY_TO_NUMBER(TRIM(e.value)) IS NOT NULL
),
ingredients AS (
  SELECT
    s."row_id",
    s."topping_id",
    1 AS count
  FROM
    standard_toppings s
    LEFT JOIN exclusions e ON s."row_id" = e."row_id" AND s."topping_id" = e."topping_id"
  WHERE
    e."topping_id" IS NULL
  UNION ALL
  SELECT
    e."row_id",
    e."topping_id",
    1 AS count
  FROM
    extras e
),
ingredients_with_counts AS (
  SELECT
    i."row_id",
    i."topping_id",
    SUM(i.count) AS total_count
  FROM
    ingredients i
  GROUP BY
    i."row_id",
    i."topping_id"
),
final_ingredients AS (
  SELECT
    i."row_id",
    LISTAGG(
      CASE
        WHEN i.total_count > 1 THEN CONCAT(i.total_count, 'x ', pt."topping_name")
        ELSE pt."topping_name"
      END,
      ', '
    ) WITHIN GROUP (
      ORDER BY
        pt."topping_name"
    ) AS final_ingredients
  FROM
    ingredients_with_counts i
    JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_TOPPINGS" pt ON i."topping_id" = pt."topping_id"
  GROUP BY
    i."row_id"
)
SELECT
  o."row_id",
  o."order_id",
  o."customer_id",
  CASE
    WHEN p."pizza_name" ILIKE '%meat%lovers%' THEN 1
    ELSE 2
  END AS "pizza_id",
  p."pizza_name",
  CONCAT(p."pizza_name", ': ', fi.final_ingredients) AS "final_ingredients"
FROM
  orders_with_row_id o
  JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_NAMES" p ON o."pizza_id" = p."pizza_id"
  LEFT JOIN final_ingredients fi ON o."row_id" = fi."row_id"
ORDER BY
  o."row_id";