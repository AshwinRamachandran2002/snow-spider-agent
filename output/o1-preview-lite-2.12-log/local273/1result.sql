WITH
ordered_orderlines AS (
    SELECT
        ol.id AS orderline_id,
        ol.order_id,
        ol.product_id,
        ol.qty AS order_qty,
        ord.ordered AS order_date,
        pr.name AS product_name,
        SUM(ol.qty) OVER (
            PARTITION BY ol.product_id
            ORDER BY ord.ordered, ol.id
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS cumulative_ordered_qty_before
    FROM "orderlines" ol
    JOIN "orders" ord ON ol."order_id" = ord."id"
    JOIN "products" pr ON ol."product_id" = pr."id"
),
product_inventory AS (
    SELECT
        i."product_id",
        SUM(i."qty") AS total_inventory_qty
    FROM "inventory" i
    GROUP BY i."product_id"
),
calculated_picks AS (
    SELECT
        ool."product_id",
        ool."product_name",
        ool."order_id",
        ool."order_qty",
        ool."order_date",
        COALESCE(ool."cumulative_ordered_qty_before", 0) AS cumulative_ordered_qty_before,
        pi.total_inventory_qty,
        pi.total_inventory_qty - COALESCE(ool."cumulative_ordered_qty_before", 0) AS remaining_inventory_before_order,
        CASE
            WHEN (pi.total_inventory_qty - COALESCE(ool."cumulative_ordered_qty_before", 0)) >= ool."order_qty" THEN ool."order_qty"
            WHEN (pi.total_inventory_qty - COALESCE(ool."cumulative_ordered_qty_before", 0)) > 0 THEN (pi.total_inventory_qty - COALESCE(ool."cumulative_ordered_qty_before", 0))
            ELSE 0
        END AS pick_qty
    FROM ordered_orderlines ool
    JOIN product_inventory pi ON ool."product_id" = pi."product_id"
)
SELECT
    "product_name",
    ROUND(AVG("pick_qty" * 100.0 / "order_qty"), 4) AS "average_pick_percentage"
FROM calculated_picks
GROUP BY "product_name"
ORDER BY "product_name";