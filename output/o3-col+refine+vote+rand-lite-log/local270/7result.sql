WITH RECURSIVE
-- 1) Identify “top-level” packages (never appear as a component)
top_pkg AS (
    SELECT id, name
    FROM   packaging
    WHERE  id NOT IN (SELECT contains_id FROM packaging_relations)
),
-- 2) Walk the full hierarchy of every top-level package,
--    multiplying quantities as we go
hier AS (
    SELECT pr.packaging_id AS top_id,
           pr.contains_id  AS item_id,
           pr.qty          AS qty
    FROM   packaging_relations pr
    WHERE  pr.packaging_id IN (SELECT id FROM top_pkg)
    UNION ALL
    SELECT h.top_id,
           pr.contains_id,
           h.qty * pr.qty
    FROM   hier h
    JOIN   packaging_relations pr
           ON pr.packaging_id = h.item_id
),
-- 3) Aggregate total quantity per (top-level container, item)
agg AS (
    SELECT top_id,
           item_id,
           SUM(qty) AS total_qty
    FROM   hier
    GROUP BY top_id, item_id
    HAVING total_qty > 500              -- keep only those that exceed 500
)
-- 4) Return the names requested
SELECT tp.name  AS container,
       p.name   AS item
FROM   agg       a
JOIN   top_pkg   tp ON tp.id = a.top_id
JOIN   packaging p  ON p.id  = a.item_id
ORDER BY tp.name, p.name;