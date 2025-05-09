WITH RECURSIVE
packaging_tree(packaging_id, item_id, qty) AS (
    -- Base case: direct contents of final packaging items
    SELECT pr.packaging_id, pr.contains_id, pr.qty
    FROM packaging_relations pr
    WHERE pr.packaging_id IN (
        SELECT id FROM packaging
        WHERE id NOT IN (SELECT contains_id FROM packaging_relations)
    )
    UNION ALL
    -- Recursive case: traverse nested packaging
    SELECT pt.packaging_id, pr.contains_id, pt.qty * pr.qty
    FROM packaging_tree pt
    JOIN packaging_relations pr ON pt.item_id = pr.packaging_id
)
SELECT AVG(total_qty) AS "average_total_quantity"
FROM (
    SELECT packaging_id, SUM(qty) AS total_qty
    FROM packaging_tree
    GROUP BY packaging_id
);