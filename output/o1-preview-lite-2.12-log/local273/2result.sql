SELECT
    p.name AS Product_Name,
    ROUND(AVG(per_orderline.pick_percentage), 4) AS Average_Pick_Percentage
FROM
    (
        SELECT
            ol.order_id,
            ol.product_id,
            ol.qty AS ordered_qty,
            COALESCE(SUM(pl.qty), 0) AS picked_qty,
            (COALESCE(SUM(pl.qty), 0) * 100.0 / ol.qty) AS pick_percentage
        FROM orderlines ol
        LEFT JOIN picking_line pl
            ON ol.order_id = pl.order_id AND ol.product_id = pl.product_id
        GROUP BY ol.order_id, ol.product_id
    ) per_orderline
JOIN products p ON per_orderline.product_id = p.id
GROUP BY p.name
ORDER BY p.name;