WITH RECURSIVE hierarchy(parent_id, item_id, qty_mult) AS (
    SELECT pr.packaging_id,
           pr.contains_id,
           pr.qty * 1.0
    FROM   packaging_relations pr
    UNION ALL
    SELECT h.parent_id,
           pr.contains_id,
           h.qty_mult * pr.qty
    FROM   hierarchy h
    JOIN   packaging_relations pr
           ON pr.packaging_id = h.item_id
),
totals AS (
    SELECT parent_id,
           item_id,
           SUM(qty_mult) AS total_qty
    FROM   hierarchy
    GROUP BY parent_id, item_id
),
top_level AS (
    SELECT id
    FROM   packaging
    WHERE  id NOT IN (SELECT contains_id FROM packaging_relations)
)
SELECT
    pc.name AS container_name,
    pi.name AS item_name
FROM   totals t
JOIN   top_level tl ON tl.id = t.parent_id
JOIN   packaging pc ON pc.id = t.parent_id
JOIN   packaging pi ON pi.id = t.item_id
WHERE  t.total_qty > 500
ORDER  BY pc.name, pi.name;