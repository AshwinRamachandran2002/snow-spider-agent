WITH first_inv AS (
  SELECT  inv.location_id,
          inv.product_id,
          MIN(pur.purchased) AS first_purchased
  FROM    inventory AS inv
  JOIN    purchases AS pur ON pur.id = inv.purchase_id
  GROUP BY inv.location_id, inv.product_id
),
chosen_inv AS (
  SELECT  inv.location_id,
          inv.product_id,
          MIN(inv.qty) AS stock_qty          -- smallest qty for that earliest purchase
  FROM    inventory AS inv
  JOIN    purchases AS pur ON pur.id = inv.purchase_id
  JOIN    first_inv  fi  ON fi.location_id = inv.location_id
                         AND fi.product_id = inv.product_id
                         AND pur.purchased = fi.first_purchased
  GROUP BY inv.location_id, inv.product_id
)
SELECT
    pr.name AS product_name,
    ROUND(
        AVG(
            1.0 * CASE
                     WHEN pl.qty > ci.stock_qty THEN ci.stock_qty
                     ELSE pl.qty
                 END / ci.stock_qty
        ) * 100,
        4
    ) AS average_pick_percentage
FROM picking_line AS pl
JOIN chosen_inv  ci ON ci.location_id = pl.location_id
                   AND ci.product_id  = pl.product_id
JOIN products    pr ON pr.id = pl.product_id
GROUP BY pr.name
ORDER BY pr.name;