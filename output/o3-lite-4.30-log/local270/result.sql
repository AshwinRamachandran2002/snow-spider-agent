WITH RECURSIVE
    top_packages AS (
        SELECT DISTINCT packaging_id
        FROM packaging_relations
        WHERE packaging_id NOT IN (SELECT contains_id FROM packaging_relations)
    ),
    hierarchy AS (
        -- anchor level
        SELECT
            pr.packaging_id AS top_id,
            pr.contains_id  AS item_id,
            pr.qty          AS path_qty
        FROM packaging_relations pr
        WHERE pr.packaging_id IN (SELECT packaging_id FROM top_packages)

        UNION ALL

        -- recursive level
        SELECT
            h.top_id,
            pr.contains_id,
            h.path_qty * pr.qty
        FROM hierarchy h
        JOIN packaging_relations pr
              ON pr.packaging_id = h.item_id
    ),
    totals AS (
        SELECT
            top_id,
            item_id,
            SUM(path_qty) AS total_qty
        FROM hierarchy
        GROUP BY top_id, item_id
        HAVING total_qty > 500
    ),
    item_names AS (
        SELECT id, name FROM packaging
        UNION
        SELECT id, name FROM products
    )
SELECT
    p_top.name AS container_name,
    i.name     AS item_name
FROM totals t
JOIN packaging p_top ON p_top.id = t.top_id
JOIN item_names i    ON i.id = t.item_id
ORDER BY container_name, item_name;