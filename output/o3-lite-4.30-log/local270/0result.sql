WITH RECURSIVE
    top_level AS (
        SELECT DISTINCT packaging_id AS id
        FROM packaging_relations
        WHERE packaging_id NOT IN (SELECT DISTINCT contains_id FROM packaging_relations)
    ),
    paths(container_id, item_id, qty) AS (
        SELECT packaging_id,
               contains_id,
               qty
        FROM packaging_relations
        UNION ALL
        SELECT p.container_id,
               pr.contains_id,
               p.qty * pr.qty
        FROM paths p
        JOIN packaging_relations pr
          ON pr.packaging_id = p.item_id
    ),
    totals AS (
        SELECT container_id,
               item_id,
               SUM(qty) AS total_qty
        FROM paths
        GROUP BY container_id, item_id
    )
SELECT pc.name AS container_name,
       pi.name AS item_name
FROM totals
JOIN top_level tl   ON tl.id = totals.container_id
JOIN packaging pc   ON pc.id = totals.container_id
JOIN packaging pi   ON pi.id = totals.item_id
WHERE totals.total_qty > 500
ORDER BY pc.name, pi.name;