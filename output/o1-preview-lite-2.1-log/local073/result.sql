WITH RECURSIVE
pizza_orders AS (
    SELECT po.*, po.rowid AS pizza_order_id
    FROM pizza_customer_orders po
),
-- Split default toppings into rows
pizza_toppings_split(pizza_id, topping_id, rest) AS (
    SELECT
        pizza_id,
        NULL,
        TRIM(toppings) || ','
    FROM pizza_recipes

    UNION ALL

    SELECT
        pizza_id,
        CAST(substr(rest, 1, instr(rest, ',') -1 ) AS INTEGER),
        substr(rest, instr(rest, ',') +1 )
    FROM pizza_toppings_split
    WHERE rest LIKE '%,%'
),
pizza_default_toppings AS (
    SELECT pizza_id, topping_id
    FROM pizza_toppings_split
    WHERE topping_id IS NOT NULL
),

-- Split order exclusions into rows
order_exclusions_split(pizza_order_id, topping_id, rest) AS (
    SELECT
        po.pizza_order_id,
        NULL,
        TRIM(po.exclusions) || ','
    FROM pizza_orders po
    WHERE po.exclusions IS NOT NULL AND TRIM(po.exclusions) != ''

    UNION ALL

    SELECT
        pizza_order_id,
        CAST(substr(rest, 1, instr(rest, ',') -1 ) AS INTEGER),
        substr(rest, instr(rest, ',') +1 )
    FROM order_exclusions_split
    WHERE rest LIKE '%,%'
),
order_exclusions AS (
    SELECT pizza_order_id, topping_id
    FROM order_exclusions_split
    WHERE topping_id IS NOT NULL
),

-- Split order extras into rows
order_extras_split(pizza_order_id, topping_id, rest) AS (
    SELECT
        po.pizza_order_id,
        NULL,
        TRIM(po.extras) || ','
    FROM pizza_orders po
    WHERE po.extras IS NOT NULL AND TRIM(po.extras) != ''

    UNION ALL

    SELECT
        pizza_order_id,
        CAST(substr(rest, 1, instr(rest, ',') -1 ) AS INTEGER),
        substr(rest, instr(rest, ',') +1 )
    FROM order_extras_split
    WHERE rest LIKE '%,%'
),
order_extras AS (
    SELECT pizza_order_id, topping_id
    FROM order_extras_split
    WHERE topping_id IS NOT NULL
),

-- Get default toppings for each pizza_order
order_default_toppings AS (
    SELECT
        po.pizza_order_id,
        pdt.topping_id
    FROM pizza_orders po
    JOIN pizza_default_toppings pdt ON po.pizza_id = pdt.pizza_id
),
-- Remove exclusions
order_toppings_after_exclusions AS (
    SELECT
        odt.pizza_order_id,
        odt.topping_id
    FROM order_default_toppings odt
    LEFT JOIN order_exclusions oe ON odt.pizza_order_id = oe.pizza_order_id AND odt.topping_id = oe.topping_id
    WHERE oe.topping_id IS NULL  -- keep toppings not in exclusions
),
-- Add extras
all_order_toppings AS (
    SELECT
        pizza_order_id,
        topping_id
    FROM order_toppings_after_exclusions
    UNION ALL
    SELECT
        pizza_order_id,
        topping_id
    FROM order_extras
),
-- Count toppings per pizza_order
order_topping_counts AS (
    SELECT
        pizza_order_id,
        topping_name,
        COUNT(*) AS count
    FROM all_order_toppings aot
    JOIN pizza_toppings pt ON aot.topping_id = pt.topping_id
    GROUP BY pizza_order_id, topping_name
),
-- Prepare the ingredients list
order_ingredients AS (
    SELECT
        pizza_order_id,
        CASE WHEN count > 1 THEN CAST(count AS TEXT) || 'x' || topping_name
             ELSE topping_name
        END AS ingredient
    FROM order_topping_counts
),
-- Aggregate ingredients per pizza_order
order_ingredients_aggregated AS (
    SELECT
        pizza_order_id,
        GROUP_CONCAT(ingredient, ';') AS ingredients
    FROM (
        SELECT
            pizza_order_id,
            ingredient
        FROM order_ingredients
        ORDER BY ingredient  -- ordering ingredients alphabetically
    ) sub
    GROUP BY pizza_order_id
)
-- Final result
SELECT
    po.order_id AS Order_ID,
    pn.pizza_name AS Pizza_Name,
    oi.ingredients AS Ingredients
FROM pizza_orders po
JOIN pizza_names pn ON po.pizza_id = pn.pizza_id
JOIN order_ingredients_aggregated oi ON po.pizza_order_id = oi.pizza_order_id
ORDER BY Order_ID, po.pizza_order_id;