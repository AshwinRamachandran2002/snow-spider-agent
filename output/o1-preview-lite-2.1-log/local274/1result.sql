WITH total_picked_qty AS (
    SELECT pl.product_id, SUM(pl.qty) AS total_picked_qty
    FROM "picking_line" pl
    WHERE pl.order_id = 421
    GROUP BY pl.product_id
),
inventory_batches AS (
    SELECT 
        i.product_id,
        pu.purchased AS purchase_date,
        i.qty AS inventory_qty,
        SUM(i.qty) OVER (PARTITION BY i.product_id ORDER BY pu.purchased) AS cumulative_qty,
        ROW_NUMBER() OVER (PARTITION BY i.product_id ORDER BY pu.purchased) AS batch_number
    FROM "inventory" i
    JOIN "purchases" pu ON i.purchase_id = pu.id
    WHERE i.product_id IN (SELECT product_id FROM total_picked_qty)
),
batches_needed AS (
    SELECT
        ib.product_id,
        MIN(ib.batch_number) AS batches_used
    FROM
        total_picked_qty tpq
    JOIN
        inventory_batches ib ON tpq.product_id = ib.product_id
    WHERE
        ib.cumulative_qty >= tpq.total_picked_qty
        AND ib.cumulative_qty - ib.inventory_qty < tpq.total_picked_qty
    GROUP BY
        ib.product_id
)
SELECT
    tpq.product_id,
    p.name AS product_name,
    ROUND(tpq.total_picked_qty * 1.0 / bn.batches_used, 4) AS average_units_picked_per_batch
FROM
    total_picked_qty tpq
JOIN
    batches_needed bn ON tpq.product_id = bn.product_id
JOIN
    "products" p ON tpq.product_id = p.id;