WITH orders_sum AS (             -- 1. total quantity ordered per product
    SELECT
        "product_id",
        SUM("qty") AS total_ordered
    FROM "orderlines"
    GROUP BY "product_id"
),
inv_fifo AS (                    -- 2. inventory batches in strict FIFO order
    SELECT
        i."product_id",
        i."id"        AS inventory_id,
        i."qty"       AS batch_qty,
        pu."purchased" AS purchase_date,
        SUM(i."qty") OVER (
            PARTITION BY i."product_id"
            ORDER BY pu."purchased", i."qty", i."id"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cume_qty
    FROM   "inventory" AS i
    JOIN   "purchases" AS pu
           ON pu."id" = i."purchase_id"
    WHERE  i."product_id" IN (SELECT "product_id" FROM orders_sum)
),
picked_per_batch AS (            -- 3. how much of each batch is actually picked
    SELECT
        f."product_id",
        CASE
            WHEN os.total_ordered - (f.cume_qty - f.batch_qty) <= 0 THEN 0         -- demand already met
            WHEN os.total_ordered >= f.cume_qty                THEN f.batch_qty    -- whole batch used
            ELSE os.total_ordered - (f.cume_qty - f.batch_qty)                    -- only part of batch used
        END AS picked_from_batch
    FROM   inv_fifo   AS f
    JOIN   orders_sum AS os
           ON os."product_id" = f."product_id"
)
SELECT
    p."name" AS product_name,
    ROUND(100.0 * SUM(pb.picked_from_batch) / os.total_ordered, 2) AS avg_pick_percentage
FROM   picked_per_batch pb
JOIN   orders_sum     os ON os."product_id" = pb."product_id"
JOIN   "products"     p  ON p."id"          = pb."product_id"
GROUP  BY pb."product_id"
ORDER  BY p."name";