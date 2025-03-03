WITH "ordered_inventory" AS (
    SELECT
        "inventory"."product_id",
        "inventory"."qty",
        "locations"."aisle",
        "locations"."position",
        "purchases"."purchased",
        ROW_NUMBER() OVER (
            PARTITION BY "inventory"."product_id"
            ORDER BY "purchases"."purchased" ASC, "inventory"."qty" ASC
        ) AS "rn"
    FROM "inventory"
    JOIN "locations" ON "inventory"."location_id" = "locations"."id"
    JOIN "purchases" ON "inventory"."purchase_id" = "purchases"."id"
    WHERE "locations"."warehouse" = 1
        AND "inventory"."product_id" IN (
            SELECT "product_id" FROM "orderlines" WHERE "order_id" = 423
        )
)
SELECT
    "oi"."product_id",
    "oi"."aisle",
    "oi"."position",
    ROUND(MIN("ol"."qty", "oi"."qty"), 4) AS "quantity_to_pick"
FROM "ordered_inventory" AS "oi"
JOIN (SELECT "product_id", "qty" FROM "orderlines" WHERE "order_id" = 423) AS "ol"
    ON "oi"."product_id" = "ol"."product_id"
WHERE "oi"."rn" = 1;