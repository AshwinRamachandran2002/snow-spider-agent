WITH RECURSIVE
cte (packaging_id, item_id, qty) AS (
    -- Base case: start from top-level containers
    SELECT pr.packaging_id, pr.contains_id, pr.qty
    FROM packaging_relations pr
    WHERE pr.packaging_id IN (
        SELECT id FROM packaging WHERE id NOT IN (SELECT contains_id FROM packaging_relations)
    )
    UNION ALL
    -- Recursive step: traverse the hierarchy
    SELECT cte.packaging_id, pr.contains_id, cte.qty * pr.qty
    FROM cte
    JOIN packaging_relations pr ON cte.item_id = pr.packaging_id
)
SELECT
    top_packaging.name AS Container_Name,
    item.name AS Item_Name
FROM
    (
        SELECT packaging_id, item_id, SUM(qty) AS total_qty
        FROM cte
        GROUP BY packaging_id, item_id
        HAVING SUM(qty) > 500
    ) total_quantities
JOIN packaging top_packaging ON top_packaging.id = total_quantities.packaging_id
JOIN packaging item ON item.id = total_quantities.item_id;