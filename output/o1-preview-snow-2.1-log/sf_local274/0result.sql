WITH total_picked AS (
    SELECT "product_id", SUM("qty") AS "total_qty_picked"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PICKING_LINE"
    WHERE "order_id" = 421
    GROUP BY "product_id"
),
inventory_batches AS (
    SELECT
        i."product_id",
        i."purchase_id",
        pu."purchased",
        i."qty",
        SUM(i."qty") OVER (
            PARTITION BY i."product_id"
            ORDER BY pu."purchased", i."purchase_id"
        ) AS "cumulative_qty",
        ROW_NUMBER() OVER (
            PARTITION BY i."product_id"
            ORDER BY pu."purchased", i."purchase_id"
        ) AS "batch_number"
    FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" i
    JOIN "ORACLE_SQL"."ORACLE_SQL"."PURCHASES" pu
        ON i."purchase_id" = pu."id"
    WHERE i."product_id" IN (SELECT "product_id" FROM total_picked)
),
batches_needed AS (
    SELECT ib.*
    FROM inventory_batches ib
    JOIN total_picked tp
        ON ib."product_id" = tp."product_id"
    WHERE ib."cumulative_qty" <= tp."total_qty_picked"
       OR ib."batch_number" = (
           SELECT MIN(ib2."batch_number")
           FROM inventory_batches ib2
           WHERE ib2."product_id" = ib."product_id"
             AND ib2."cumulative_qty" >= tp."total_qty_picked"
       )
),
final_result AS (
    SELECT
        ib."product_id",
        COUNT(DISTINCT ib."batch_number") AS "batches_used",
        tp."total_qty_picked"
    FROM batches_needed ib
    JOIN total_picked tp
        ON ib."product_id" = tp."product_id"
    GROUP BY ib."product_id", tp."total_qty_picked"
)
SELECT
    fr."product_id",
    p."name" AS "product_name",
    ROUND(fr."total_qty_picked" / fr."batches_used", 4) AS "average_units_picked_per_batch"
FROM final_result fr
JOIN "ORACLE_SQL"."ORACLE_SQL"."PRODUCTS" p
    ON fr."product_id" = p."id";