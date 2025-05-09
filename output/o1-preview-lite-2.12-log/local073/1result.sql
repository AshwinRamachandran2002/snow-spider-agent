WITH orders AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY o."order_id", o."customer_id", o."pizza_id", o."order_time") AS row_id,
        o."order_id",
        o."customer_id",
        CASE WHEN pn."pizza_name" = 'Meatlovers' THEN 1 ELSE 2 END AS pizza_id,
        pn."pizza_name",
        o."exclusions",
        o."extras",
        o."order_time",
        pr."toppings" AS standard_toppings
    FROM
        "pizza_clean_customer_orders" AS o
    JOIN
        "pizza_names" AS pn ON o."pizza_id" = pn."pizza_id"
    JOIN
        "pizza_recipes" AS pr ON o."pizza_id" = pr."pizza_id"
),
standard_toppings AS (
    SELECT
        o.row_id,
        value AS topping_id
    FROM
        orders o,
        json_each('[' || o.standard_toppings || ']')
),
exclusions AS (
    SELECT
        o.row_id,
        value AS topping_id
    FROM
        orders o,
        json_each('[' || o."exclusions" || ']')
    WHERE
        o."exclusions" IS NOT NULL
),
final_standard_toppings AS (
    SELECT
        st.row_id,
        st.topping_id
    FROM
        standard_toppings st
    LEFT JOIN
        exclusions e ON st.row_id = e.row_id AND st.topping_id = e.topping_id
    WHERE
        e.topping_id IS NULL
),
extras AS (
    SELECT
        o.row_id,
        value AS topping_id
    FROM
        orders o,
        json_each('[' || o."extras" || ']')
    WHERE
        o."extras" IS NOT NULL
),
all_toppings AS (
    SELECT
        row_id,
        topping_id,
        COUNT(*) AS count
    FROM (
        SELECT
            row_id,
            topping_id
        FROM
            final_standard_toppings
        UNION ALL
        SELECT
            row_id,
            topping_id
        FROM
            extras
    )
    GROUP BY
        row_id,
        topping_id
),
toppings_with_names AS (
    SELECT
        at.row_id,
        pt."topping_name",
        at.count
    FROM
        all_toppings at
    JOIN
        "pizza_toppings" pt ON at.topping_id = pt."topping_id"
),
final_ingredients AS (
    SELECT
        row_id,
        GROUP_CONCAT(
            CASE
                WHEN count > 1 THEN '2x' || pt."topping_name"
                ELSE pt."topping_name"
            END,
            ', '
            ORDER BY pt."topping_name"
        ) AS ingredients
    FROM
        toppings_with_names pt
        GROUP BY
            row_id
)
SELECT
    o.row_id,
    o."order_id",
    o."customer_id",
    o."pizza_name",
    o."pizza_name" || ': ' || fi.ingredients AS final_ingredients
FROM
    orders o
JOIN
    final_ingredients fi ON o.row_id = fi.row_id
ORDER BY
    o.row_id;