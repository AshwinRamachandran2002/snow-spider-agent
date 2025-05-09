WITH RECURSIVE cte (top_id, top_name, id, name, qty) AS (
    SELECT
        p.id AS top_id,
        p.name AS top_name,
        p.id,
        p.name,
        1.0 AS qty
    FROM
        packaging p
    WHERE
        p.id NOT IN (SELECT contains_id FROM packaging_relations)
    UNION ALL
    SELECT
        cte.top_id,
        cte.top_name,
        pr.contains_id,
        c.name,
        cte.qty * pr.qty
    FROM
        cte
    JOIN
        packaging_relations pr ON pr.packaging_id = cte.id
    JOIN
        packaging c ON c.id = pr.contains_id
)
SELECT DISTINCT cte.top_name AS Container_Name, cte.name AS Item_Name
FROM cte
WHERE cte.qty > 500
  AND cte.id NOT IN (SELECT packaging_id FROM packaging_relations);