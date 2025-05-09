WITH OrderProducts AS (
    SELECT "product_id", SUM("qty") AS "total_order_qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."ORDERLINES"
    WHERE "order_id" = 423
    GROUP BY "product_id"
),
InventoryData AS (
    SELECT
        i."product_id",
        i."qty" AS "inventory_qty",
        l."aisle",
        l."position",
        p."purchased" AS "purchased_date"
    FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" i
    JOIN "ORACLE_SQL"."ORACLE_SQL"."LOCATIONS" l ON i."location_id" = l."id"
    JOIN "ORACLE_SQL"."ORACLE_SQL"."PURCHASES" p ON i."purchase_id" = p."id"
    WHERE l."warehouse" = 1
      AND i."product_id" IN (SELECT "product_id" FROM OrderProducts)
),
InventoryWithCumSum AS (
    SELECT
        i."product_id",
        i."inventory_qty",
        i."aisle",
        i."position",
        i."purchased_date",
        SUM(i."inventory_qty") OVER (
            PARTITION BY i."product_id"
            ORDER BY i."purchased_date", i."inventory_qty"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "cumulative_qty"
    FROM InventoryData i
),
PickingPlan AS (
    SELECT
        i."product_id",
        i."aisle",
        i."position",
        i."inventory_qty",
        i."purchased_date",
        LEAST(
            i."inventory_qty",
            GREATEST(
                o."total_order_qty" - (i."cumulative_qty" - i."inventory_qty"),
                0
            )
        ) AS "qty_to_pick"
    FROM InventoryWithCumSum i
    JOIN OrderProducts o ON i."product_id" = o."product_id"
    WHERE LEAST(
        i."inventory_qty",
        GREATEST(
            o."total_order_qty" - (i."cumulative_qty" - i."inventory_qty"),
            0
        )
    ) > 0
)
SELECT
    "product_id", "aisle", "position", ROUND("qty_to_pick", 4) AS "qty_to_pick"
FROM PickingPlan
ORDER BY "product_id", "purchased_date", "inventory_qty";