WITH "PickedProducts" AS (
    SELECT 
        pl."product_id", 
        SUM(pl."qty") AS "picked_qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PICKING_LINE" pl
    WHERE pl."order_id" = 421
    GROUP BY pl."product_id"
),
"InventoryBatches" AS (
    SELECT 
        i."product_id", 
        i."purchase_id", 
        pur."purchased" AS "purchase_date", 
        i."qty" AS "inventory_qty",
        SUM(i."qty") OVER (
            PARTITION BY i."product_id" 
            ORDER BY pur."purchased" ASC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "cumulative_inventory_qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" i
    JOIN "ORACLE_SQL"."ORACLE_SQL"."PURCHASES" pur ON i."purchase_id" = pur."id"
    WHERE i."product_id" IN (
        SELECT "product_id"
        FROM "ORACLE_SQL"."ORACLE_SQL"."PICKING_LINE"
        WHERE "order_id" = 421
    )
),
"UsedBatches" AS (
    SELECT 
        ib."product_id", 
        ib."purchase_id", 
        ib."purchase_date", 
        ib."inventory_qty", 
        ib."cumulative_inventory_qty", 
        pp."picked_qty",
        CASE 
            WHEN ib."cumulative_inventory_qty" <= pp."picked_qty" THEN ib."inventory_qty"
            ELSE pp."picked_qty" - (ib."cumulative_inventory_qty" - ib."inventory_qty")
        END AS "qty_used_from_batch"
    FROM "InventoryBatches" ib
    JOIN "PickedProducts" pp ON ib."product_id" = pp."product_id"
    WHERE ib."cumulative_inventory_qty" - ib."inventory_qty" < pp."picked_qty"
),
"BatchesUsedPerProduct" AS (
    SELECT 
        ub."product_id", 
        COUNT(*) AS "batches_used", 
        SUM(ub."qty_used_from_batch") AS "total_qty_used"
    FROM "UsedBatches" ub
    GROUP BY ub."product_id"
)
SELECT 
    pp."product_id", 
    p."name" AS "product_name", 
    ROUND(pp."picked_qty" / bu."batches_used", 4) AS "average_units_picked_per_batch"
FROM "PickedProducts" pp
JOIN "BatchesUsedPerProduct" bu ON pp."product_id" = bu."product_id"
JOIN "ORACLE_SQL"."ORACLE_SQL"."PRODUCTS" p ON pp."product_id" = p."id";