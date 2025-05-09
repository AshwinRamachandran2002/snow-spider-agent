WITH earliest_purchased AS (
    SELECT
        i.product_id,
        MIN(p.purchased) AS earliest_purchased
    FROM inventory i
    JOIN purchases p ON i.purchase_id = p.id
    JOIN locations l ON i.location_id = l.id
    WHERE i.product_id IN (SELECT product_id FROM orderlines WHERE order_id = 423)
      AND l.warehouse = 1
    GROUP BY i.product_id
), min_qty AS (
    SELECT
        i.product_id,
        MIN(i.qty) AS min_qty
    FROM inventory i
    JOIN purchases p ON i.purchase_id = p.id
    JOIN locations l ON i.location_id = l.id
    JOIN earliest_purchased ep ON i.product_id = ep.product_id AND p.purchased = ep.earliest_purchased
    WHERE l.warehouse = 1
    GROUP BY i.product_id
)
SELECT
    i.product_id,
    l.aisle,
    l.position,
    ROUND(
        CASE
            WHEN i.qty >= o.required_qty THEN o.required_qty
            ELSE i.qty
        END, 4
    ) AS quantity_to_pick
FROM inventory i
JOIN purchases p ON i.purchase_id = p.id
JOIN locations l ON i.location_id = l.id
JOIN earliest_purchased ep ON i.product_id = ep.product_id AND p.purchased = ep.earliest_purchased
JOIN min_qty mq ON i.product_id = mq.product_id AND i.qty = mq.min_qty
JOIN (SELECT product_id, qty AS required_qty FROM orderlines WHERE order_id = 423) o ON i.product_id = o.product_id
WHERE l.warehouse = 1;