WITH product_inventory AS (          -- total stock on hand per product
    SELECT
        "product_id",
        SUM("qty") AS total_inventory
    FROM "inventory"
    GROUP BY "product_id"
),

product_orders AS (                  -- every order line with its order date
    SELECT
        ol."order_id",
        ol."product_id",
        ol."qty"        AS ordered_qty,
        o."ordered"     AS ordered_date
    FROM "orderlines" AS ol
    JOIN "orders"      AS o
      ON o."id" = ol."order_id"
),

orders_with_running_sum AS (         -- running total of demand before each order (FIFO)
    SELECT
        po.*,
        COALESCE(
            SUM(po.ordered_qty) OVER (
                PARTITION BY po.product_id
                ORDER BY po.ordered_date, po.order_id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ), 0
        ) AS cum_before
    FROM product_orders AS po
),

allocated AS (                       -- overlap between demand and remaining stock
    SELECT
        owrs.product_id,
        owrs.ordered_qty,
        CASE
            WHEN pi.total_inventory - owrs.cum_before <= 0             THEN 0.0
            WHEN pi.total_inventory >= owrs.cum_before + owrs.ordered_qty
                                                                  THEN owrs.ordered_qty * 1.0
            ELSE  pi.total_inventory - owrs.cum_before
        END AS picked_qty
    FROM orders_with_running_sum AS owrs
    JOIN product_inventory      AS pi
      ON pi.product_id = owrs.product_id
),

percentages AS (                     -- pick‑percentage for every order line
    SELECT
        product_id,
        picked_qty / ordered_qty AS pick_pct
    FROM allocated
)

SELECT
    pr."name"                      AS product_name,
    ROUND(AVG(pick_pct) * 100, 4)  AS average_pick_percentage
FROM percentages
JOIN "products" AS pr
  ON pr."id" = percentages.product_id
GROUP BY pr."name"
ORDER BY pr."name";