WITH RECURSIVE packaging_tree(packaging_id, contains_id, total_qty) AS (
    -- Base case: Direct relationships from packaging_relations
    SELECT pr.packaging_id, pr.contains_id, pr.qty
    FROM packaging_relations pr

    UNION ALL

    -- Recursive case: Expand nested packaging relationships
    SELECT pt.packaging_id, pr.contains_id, pt.total_qty * pr.qty
    FROM packaging_tree pt
    JOIN packaging_relations pr ON pt.contains_id = pr.packaging_id
)
SELECT AVG(total_quantity) AS average_total_quantity
FROM (
    -- Calculate total quantities of leaf-level items for each top-level packaging
    SELECT pt.packaging_id, SUM(pt.total_qty) AS total_quantity
    FROM packaging_tree pt
    -- Identify leaf-level items (those not containing other items)
    LEFT JOIN packaging_relations pr ON pt.contains_id = pr.packaging_id
    -- Only consider leaf-level items (where contains_id is not a packaging_id)
    WHERE pr.packaging_id IS NULL
    -- Only consider top-level packaging (not contained in any other packaging)
    AND pt.packaging_id NOT IN (SELECT contains_id FROM packaging_relations)
    GROUP BY pt.packaging_id
);