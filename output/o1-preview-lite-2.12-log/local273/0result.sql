WITH ordered_inventory AS (
    SELECT
        ol.order_id,
        ol.product_id,
        p.name,
        ol.qty AS required_quantity,
        i.id AS inventory_id,
        i.qty AS inventory_qty,
        pu.purchased,
        SUM(i.qty) OVER (
            PARTITION BY ol.order_id, ol.product_id
            ORDER BY pu.purchased, i.qty, i.id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_qty
    FROM orderlines ol
    JOIN products p ON ol.product_id = p.id
    JOIN inventory i ON ol.product_id = i.product_id
    JOIN purchases pu ON i.purchase_id = pu.id
),
picked_inventory AS (
    SELECT
        *,
        CASE
            WHEN cumulative_qty - inventory_qty >= required_quantity THEN 0
            WHEN cumulative_qty <= required_quantity THEN inventory_qty
            ELSE required_quantity - (cumulative_qty - inventory_qty)
        END AS picked_qty
    FROM ordered_inventory
),
per_orderline AS (
    SELECT
        order_id,
        product_id,
        name,
        required_quantity,
        SUM(picked_qty) AS total_picked_qty,
        (SUM(picked_qty) * 100.0 / required_quantity) AS pick_percentage
    FROM picked_inventory
    GROUP BY order_id, product_id, name, required_quantity
)
SELECT
    name AS "Product_Name",
    ROUND(AVG(pick_percentage), 4) AS Average_Pick_Percentage
FROM per_orderline
GROUP BY name
ORDER BY name;