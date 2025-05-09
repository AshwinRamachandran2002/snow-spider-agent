WITH
order_exclusions AS (
    SELECT co."order_id", TRIM(ex.value::VARCHAR) AS "topping_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS co,
    LATERAL FLATTEN(input => SPLIT(co."exclusions", ',')) ex
    WHERE co."exclusions" IS NOT NULL AND co."exclusions" != ''
),
order_extras AS (
    SELECT co."order_id", TRIM(extr.value::VARCHAR) AS "topping_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS co,
    LATERAL FLATTEN(input => SPLIT(co."extras", ',')) extr
    WHERE co."extras" IS NOT NULL AND co."extras" != ''
),
delivered_orders AS (
    SELECT co."order_id", co."pizza_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS co
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS cro
      ON co."order_id" = cro."order_id"
    WHERE cro."cancellation" IS NULL OR cro."cancellation" = ''
),
base_toppings AS (
    SELECT do."order_id", do."pizza_id",
           TRIM(bt.value::VARCHAR) AS "topping_id"
    FROM delivered_orders do
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_RECIPES pr
      ON do."pizza_id" = pr."pizza_id",
    LATERAL FLATTEN(input => SPLIT(pr."toppings", ',')) bt
),
final_toppings AS (
    -- Base toppings after applying exclusions
    SELECT bt."order_id", bt."topping_id"
    FROM base_toppings bt
    LEFT JOIN order_exclusions oe
      ON bt."order_id" = oe."order_id" AND bt."topping_id" = oe."topping_id"
    WHERE oe."topping_id" IS NULL
    UNION ALL
    -- Add the extras
    SELECT ex."order_id", ex."topping_id"
    FROM order_extras ex
    JOIN delivered_orders do
      ON ex."order_id" = do."order_id"
)
SELECT pt."topping_name" AS "Name", COUNT(*) AS "Quantity"
FROM final_toppings ft
JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
  ON ft."topping_id" = pt."topping_id"
GROUP BY pt."topping_name"
ORDER BY "Quantity" DESC NULLS LAST;