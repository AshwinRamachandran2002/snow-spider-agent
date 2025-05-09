WITH RECURSIVE
    -- Expand every parent-child path, multiplying quantities along the way
    tree(parent_id, child_id, qty) AS (
        SELECT
            pr.packaging_id,
            pr.contains_id,
            pr.qty
        FROM packaging_relations AS pr
        UNION ALL
        SELECT
            t.parent_id,
            pr.contains_id,
            t.qty * pr.qty
        FROM tree AS t
        JOIN packaging_relations AS pr
          ON pr.packaging_id = t.child_id
    ),
    -- Identify leaf-level packaging items (never appear as a parent)
    leaves AS (
        SELECT id AS leaf_id
        FROM packaging
        WHERE id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
    ),
    -- For each top-level packaging combination, sum all leaf quantities
    totals AS (
        SELECT
            parent_id,
            SUM(qty) AS total_leaf_qty
        FROM tree
        WHERE child_id IN (SELECT leaf_id FROM leaves)
        GROUP BY parent_id
    )
-- Average of those total leaf quantities
SELECT AVG(total_leaf_qty) AS average_total_leaf_qty
FROM totals;