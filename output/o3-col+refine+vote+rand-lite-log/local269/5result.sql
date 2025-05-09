WITH RECURSIVE r(parent_id, leaf_id, qty) AS (
    -- direct relations
    SELECT
        packaging_id,
        contains_id,
        qty
    FROM packaging_relations

    UNION ALL

    -- follow any child that is itself a parent, multiplying quantities
    SELECT
        r.parent_id,
        pr.contains_id,
        r.qty * pr.qty
    FROM r
    JOIN packaging_relations AS pr
      ON pr.packaging_id = r.leaf_id
),
per_package AS (
    -- sum up all leaf quantities for each top-level package
    SELECT
        parent_id,
        SUM(qty) AS total_leaf_qty
    FROM r
    GROUP BY parent_id
)
-- final answer: average of those totals
SELECT
    AVG(total_leaf_qty) AS avg_total_quantity_per_package
FROM per_package;