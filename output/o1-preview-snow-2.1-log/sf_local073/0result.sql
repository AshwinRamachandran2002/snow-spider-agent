WITH default_toppings AS (
    SELECT
        co."order_id",
        TRY_CAST(TRIM(dt.value) AS INTEGER) AS "topping_id"
    FROM
        "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" co
        JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_RECIPES" pr ON co."pizza_id" = pr."pizza_id",
        LATERAL FLATTEN(INPUT => SPLIT(pr."toppings", ',')) dt
    WHERE
        TRIM(dt.value) != ''
        AND TRY_CAST(TRIM(dt.value) AS INTEGER) IS NOT NULL
),
exclusions AS (
    SELECT
        co."order_id",
        TRY_CAST(TRIM(excl.value) AS INTEGER) AS "topping_id"
    FROM
        "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" co,
        LATERAL FLATTEN(INPUT => SPLIT(co."exclusions", ',')) excl
    WHERE
        co."exclusions" IS NOT NULL
        AND TRIM(excl.value) != ''
        AND TRY_CAST(TRIM(excl.value) AS INTEGER) IS NOT NULL
),
default_toppings_clean AS (
    SELECT
        dt."order_id",
        dt."topping_id"
    FROM
        default_toppings dt
    LEFT JOIN
        exclusions ex ON dt."order_id" = ex."order_id" AND dt."topping_id" = ex."topping_id"
    WHERE
        ex."topping_id" IS NULL
),
extras AS (
    SELECT
        co."order_id",
        TRY_CAST(TRIM(extr.value) AS INTEGER) AS "topping_id"
    FROM
        "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" co,
        LATERAL FLATTEN(INPUT => SPLIT(co."extras", ',')) extr
    WHERE
        co."extras" IS NOT NULL
        AND TRIM(extr.value) != ''
        AND TRY_CAST(TRIM(extr.value) AS INTEGER) IS NOT NULL
),
combined_toppings AS (
    SELECT
        dtc."order_id",
        dtc."topping_id"
    FROM
        default_toppings_clean dtc
    UNION ALL
    SELECT
        ex."order_id",
        ex."topping_id"
    FROM
        extras ex
),
toppings_count AS (
    SELECT
        ct."order_id",
        ct."topping_id",
        COUNT(*) AS "count"
    FROM
        combined_toppings ct
    GROUP BY
        ct."order_id",
        ct."topping_id"
),
toppings_names AS (
    SELECT
        tc."order_id",
        tc."count",
        pt."topping_name"
    FROM
        toppings_count tc
    JOIN
        "MODERN_DATA"."MODERN_DATA"."PIZZA_TOPPINGS" pt ON tc."topping_id" = pt."topping_id"
),
toppings_formatted AS (
    SELECT
        tn."order_id",
        CASE
            WHEN tn."count" > 1 THEN CONCAT(tn."count", 'x', tn."topping_name")
            ELSE tn."topping_name"
        END AS "topping"
    FROM
        toppings_names tn
),
toppings_list AS (
    SELECT
        tf."order_id",
        LISTAGG(tf."topping", ', ') WITHIN GROUP (ORDER BY tf."topping") AS "toppings"
    FROM
        toppings_formatted tf
    GROUP BY
        tf."order_id"
),
pizza_orders AS (
    SELECT
        co."order_id",
        pn."pizza_name"
    FROM
        "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" co
    JOIN
        "MODERN_DATA"."MODERN_DATA"."PIZZA_NAMES" pn ON co."pizza_id" = pn."pizza_id"
),
final_result AS (
    SELECT
        po."order_id",
        CONCAT(po."pizza_name", ': ', tl."toppings") AS "Pizza_Details"
    FROM
        pizza_orders po
    JOIN
        toppings_list tl ON po."order_id" = tl."order_id"
)
SELECT
    "order_id",
    "Pizza_Details"
FROM
    final_result
ORDER BY
    "order_id";