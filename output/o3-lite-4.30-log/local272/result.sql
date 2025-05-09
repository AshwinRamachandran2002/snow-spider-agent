WITH order_reqs AS (                       -- quantities requested in order 423
    SELECT "product_id",
           SUM("qty") AS "order_qty"
    FROM   "orderlines"
    WHERE  "order_id" = 423
    GROUP BY "product_id"
),
inv_ranked AS (                            -- warehouse‑1 inventory ranked FIFO + small lot
    SELECT  i."id" AS "inventory_id",
            i."product_id",
            i."qty",
            p."purchased",
            l."aisle",
            l."position",
            COALESCE(
                SUM(i."qty") OVER (
                    PARTITION BY i."product_id"
                    ORDER BY p."purchased", i."qty", i."id"
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ),0
            )           AS "running_qty",
            r."order_qty"
    FROM   "inventory"  AS i
    JOIN   "purchases"  AS p  ON p."id" = i."purchase_id"
    JOIN   "locations"  AS l  ON l."id" = i."location_id"
    JOIN   order_reqs   AS r  ON r."product_id" = i."product_id"
    WHERE  l."warehouse" = 1
),
pick_rows AS (                             -- decide how much to take from each row
    SELECT  "product_id",
            "aisle",
            "position",
            CASE
                WHEN running_qty >= order_qty         THEN 0
                WHEN running_qty + qty <= order_qty   THEN qty
                ELSE order_qty - running_qty
            END AS "pick_qty"
    FROM   inv_ranked
)
SELECT  "product_id",
        "aisle",
        "position",
        printf('%.4f', SUM("pick_qty")) AS "pick_qty"
FROM    pick_rows
WHERE   "pick_qty" > 0
GROUP BY "product_id", "aisle", "position"
ORDER BY "product_id", "aisle", "position";