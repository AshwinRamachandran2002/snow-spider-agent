WITH RECURSIVE parts(parent_id, leaf_id, leaf_qty) AS (
    SELECT
        packaging_id,
        contains_id,
        qty
    FROM packaging_relations
    UNION ALL
    SELECT
        pr.packaging_id,
        parts.leaf_id,
        pr.qty * parts.leaf_qty
    FROM parts
    JOIN packaging_relations AS pr
      ON pr.contains_id = parts.parent_id
),
leaf_totals AS (
    SELECT
        parent_id AS packaging_id,
        leaf_id,
        SUM(leaf_qty) AS leaf_qty
    FROM parts
    WHERE leaf_id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
    GROUP BY parent_id, leaf_id
),
combo_totals AS (
    SELECT
        packaging_id,
        SUM(leaf_qty) AS total_leaf_qty
    FROM leaf_totals
    GROUP BY packaging_id
)
SELECT
    ROUND(AVG(total_leaf_qty), 4) AS average_total_quantity
FROM combo_totals;