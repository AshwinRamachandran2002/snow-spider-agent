WITH
/* 1. order lines for order 423 ------------------------------------------- */
order_items AS (
    SELECT
        id            AS orderline_id,
        product_id,
        qty           AS order_qty
    FROM orderlines
    WHERE order_id = 423
),

/* 2. total quantity per product that has to be picked -------------------- */
order_totals AS (
    SELECT
        product_id,
        SUM(order_qty) AS need_qty
    FROM order_items
    GROUP BY product_id
),

/* 3. inventory in warehouse 1 for the products in the order -------------- */
inv AS (
    SELECT
        i.id                AS inventory_id,
        i.product_id,
        i.qty               AS inv_qty,
        l.aisle,
        l.position,
        p.purchased         AS purchased_date
    FROM inventory   i
    JOIN locations   l ON l.id = i.location_id        -- gives aisle / position / warehouse
    JOIN purchases   p ON p.id = i.purchase_id        -- gives purchase date
    WHERE l.warehouse = 1
      AND i.product_id IN (SELECT product_id FROM order_totals)
),

/* 4. add running total to know how much is still needed ------------------ */
ordered_inv AS (
    SELECT
        inv.product_id,
        inv.aisle,
        inv.position,
        inv.inv_qty,
        ot.need_qty,
        inv.purchased_date,
        /* cumulative quantity BEFORE this inventory row */
        COALESCE(
            SUM(inv.inv_qty) OVER (
                PARTITION BY inv.product_id
                ORDER BY inv.purchased_date,
                         inv.inv_qty,
                         inv.inventory_id      -- tie‑breaker
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),
            0
        ) AS picked_before
    FROM inv
    JOIN order_totals ot USING (product_id)
)

/* 5. decide exactly how much to pick from each location ------------------ */
SELECT
    product_id,
    aisle,
    position,
    /* quantity to pick from this location */
    CASE
        WHEN picked_before >= need_qty          -- already picked enough
             THEN 0
        WHEN picked_before + inv_qty <= need_qty -- can take everything here
             THEN inv_qty
        ELSE                                      -- take only what is still missing
             need_qty - picked_before
    END AS pick_qty
FROM ordered_inv
WHERE picked_before < need_qty       -- skip locations that are not needed
ORDER BY
    product_id,
    purchased_date,                  -- earliest purchases first
    inv_qty,                         -- smaller batches first
    aisle,
    position;