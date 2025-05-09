SELECT
    pr."id" AS product_id,
    ROUND(AVG(pl."qty"), 4) AS average_units_picked
FROM "picking_line" AS pl
JOIN "picking_list" AS plst
  ON plst."id" = pl."picklist_id"
JOIN "products" AS pr
  ON pr."id" = pl."product_id"
WHERE pl."order_id" = 421
GROUP BY pr."id"
ORDER BY MIN(plst."created"),
         MIN(pl."line_no");