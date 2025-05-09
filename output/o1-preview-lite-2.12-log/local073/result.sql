WITH OrdersWithRowID AS (
    SELECT ROW_NUMBER() OVER (ORDER BY "order_time", "order_id", pn."pizza_name") AS "row_id",
           pco."order_id",
           pco."customer_id",
           CASE WHEN pn."pizza_name" = 'Meatlovers' THEN 1 ELSE 2 END AS "pizza_id",
           pn."pizza_name",
           pco."exclusions",
           pco."extras",
           pco."order_time"
    FROM "pizza_customer_orders" pco
    JOIN "pizza_names" pn ON pco."pizza_id" = pn."pizza_id"
),
StandardToppingsRaw AS (
    SELECT owr.*,
           pr."toppings" AS "standard_toppings"
    FROM OrdersWithRowID owr
    JOIN "pizza_recipes" pr ON owr."pizza_id" = pr."pizza_id"
),
StandardToppingsSplit AS (
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name",
           TRIM(SUBSTR("standard_toppings", 1, INSTR("standard_toppings" || ',', ',') - 1)) AS "topping_id",
           SUBSTR("standard_toppings" || ',', INSTR("standard_toppings" || ',', ',') + 1) AS "rest"
    FROM StandardToppingsRaw
    UNION ALL
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name",
           TRIM(SUBSTR("rest", 1, INSTR("rest", ',') - 1)) AS "topping_id",
           SUBSTR("rest", INSTR("rest", ',') + 1)
    FROM StandardToppingsSplit
    WHERE "rest" <> ''
),
StandardToppings AS (
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name", CAST("topping_id" AS INTEGER) AS "topping_id"
    FROM StandardToppingsSplit
    WHERE "topping_id" <> ''
),
ExclusionsSplit AS (
    SELECT owr."row_id", owr."order_id", owr."customer_id", owr."pizza_id", owr."pizza_name",
           TRIM(SUBSTR("exclusions", 1, INSTR("exclusions" || ',', ',') - 1)) AS "topping_id",
           SUBSTR("exclusions" || ',', INSTR("exclusions" || ',', ',') + 1) AS "rest"
    FROM OrdersWithRowID owr
    WHERE "exclusions" IS NOT NULL AND "exclusions" <> ''
    UNION ALL
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name",
           TRIM(SUBSTR("rest", 1, INSTR("rest", ',') - 1)) AS "topping_id",
           SUBSTR("rest", INSTR("rest", ',') + 1)
    FROM ExclusionsSplit
    WHERE "rest" <> ''
),
Exclusions AS (
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name", CAST("topping_id" AS INTEGER) AS "topping_id"
    FROM ExclusionsSplit
    WHERE "topping_id" <> ''
),
ExtrasSplit AS (
    SELECT owr."row_id", owr."order_id", owr."customer_id", owr."pizza_id", owr."pizza_name",
           TRIM(SUBSTR("extras", 1, INSTR("extras" || ',', ',') - 1)) AS "topping_id",
           SUBSTR("extras" || ',', INSTR("extras" || ',', ',') + 1) AS "rest"
    FROM OrdersWithRowID owr
    WHERE "extras" IS NOT NULL AND "extras" <> ''
    UNION ALL
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name",
           TRIM(SUBSTR("rest", 1, INSTR("rest", ',') - 1)) AS "topping_id",
           SUBSTR("rest", INSTR("rest", ',') + 1)
    FROM ExtrasSplit
    WHERE "rest" <> ''
),
Extras AS (
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name", CAST("topping_id" AS INTEGER) AS "topping_id"
    FROM ExtrasSplit
    WHERE "topping_id" <> ''
),
StandardToppingsAfterExclusions AS (
    SELECT st.*
    FROM StandardToppings st
    LEFT JOIN Exclusions e ON st."row_id" = e."row_id" AND st."topping_id" = e."topping_id"
    WHERE e."topping_id" IS NULL
),
CombinedToppings AS (
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name", "topping_id"
    FROM StandardToppingsAfterExclusions
    UNION ALL
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name", "topping_id"
    FROM Extras
),
FinalToppings AS (
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name", "topping_id", COUNT(*) AS "count"
    FROM CombinedToppings
    GROUP BY "row_id", "topping_id"
),
FinalToppingsWithNames AS (
    SELECT ft."row_id", ft."order_id", ft."customer_id", ft."pizza_id", ft."pizza_name",
           ft."topping_id", ft."count", pt."topping_name"
    FROM FinalToppings ft
    JOIN "pizza_toppings" pt ON ft."topping_id" = pt."topping_id"
),
ToppingsPerOrder AS (
    SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name",
        GROUP_CONCAT("topping_with_count", ', ') AS "toppings_list"
    FROM (
        SELECT "row_id", "order_id", "customer_id", "pizza_id", "pizza_name",
            CASE WHEN "count" > 1 THEN '2x ' || "topping_name" ELSE "topping_name" END AS "topping_with_count"
        FROM FinalToppingsWithNames
        ORDER BY "row_id", "topping_with_count" COLLATE NOCASE
    )
    GROUP BY "row_id", "order_id", "customer_id", "pizza_id", "pizza_name"
),
FinalResult AS (
    SELECT owr."row_id", owr."order_id", owr."customer_id", owr."pizza_name",
           (owr."pizza_name" || ': ' || tpo."toppings_list") AS "final_ingredients"
    FROM OrdersWithRowID owr
    JOIN ToppingsPerOrder tpo ON owr."row_id" = tpo."row_id"
)
SELECT "row_id", "order_id", "customer_id", "pizza_name", "final_ingredients"
FROM FinalResult
ORDER BY "row_id";