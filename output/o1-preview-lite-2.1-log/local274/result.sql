WITH picked_qty AS (
    SELECT
        pl."product_id",
        SUM(pl."qty") AS total_picked_qty
    FROM "picking_line" pl
    WHERE pl."order_id" = 421
    GROUP BY pl."product_id"
),
product_batches AS (
    SELECT
        i."product_id",
        i."purchase_id",
        SUM(i."qty") AS batch_qty,
        pu."purchased"
    FROM "inventory" i
    JOIN "purchases" pu ON i."purchase_id" = pu."id"
    WHERE i."product_id" IN (SELECT "product_id" FROM picked_qty)
    GROUP BY i."product_id", i."purchase_id", pu."purchased"
),
batches_cumsum AS (
    SELECT
        pb."product_id",
        pb."purchase_id",
        pb.batch_qty,
        pb."purchased",
        SUM(pb.batch_qty) OVER (
            PARTITION BY pb."product_id"
            ORDER BY pb."purchased"
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_qty
    FROM product_batches pb
),
batches_with_rownum AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "product_id"
            ORDER BY "purchased"
        ) AS batch_number
    FROM batches_cumsum
),
batches_needed AS (
    SELECT
        bw."product_id",
        MIN(bw.batch_number) AS batches_used
    FROM batches_with_rownum bw
    JOIN picked_qty pq ON bw."product_id" = pq."product_id"
    WHERE bw.cumulative_qty >= pq.total_picked_qty
    GROUP BY bw."product_id"
),
avg_units_per_batch AS (
    SELECT
        pq."product_id",
        pq.total_picked_qty,
        bn.batches_used,
        (pq.total_picked_qty * 1.0) / bn.batches_used AS average_units_picked_per_batch
    FROM picked_qty pq
    JOIN batches_needed bn ON pq."product_id" = bn."product_id"
)
SELECT
    apb."product_id",
    p."name" AS product_name,
    ROUND(apb.average_units_picked_per_batch, 4) AS average_units_picked_per_batch
FROM avg_units_per_batch apb
JOIN "products" p ON apb."product_id" = p."id";