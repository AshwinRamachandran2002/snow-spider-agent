SELECT
    pl."product_id",
    pr."name"                     AS product_name,
    AVG(pl."qty")                 AS avg_units_picked
FROM   picking_line  pl
JOIN   picking_list  plst ON pl."picklist_id" = plst."id"
JOIN   products      pr   ON pr."id"         = pl."product_id"
WHERE  pl."order_id" = 421                  -- the order in question
GROUP  BY pl."product_id", pr."name";