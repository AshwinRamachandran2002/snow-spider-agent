WITH RECURSIVE expansion(packaging_id, leaf_id, qty) AS (
    -- first level relationships
    SELECT
        packaging_id,
        contains_id,
        qty
    FROM packaging_relations

    UNION ALL

    -- recursive step: follow any nested package and multiply quantities
    SELECT
        e.packaging_id,
        pr.contains_id,
        e.qty * pr.qty
    FROM expansion        AS e
    JOIN packaging_relations AS pr
         ON pr.packaging_id = e.leaf_id
),
leaf_totals AS (
    -- keep only “leaf” components (those that never act as a parent)
    SELECT
        packaging_id,
        SUM(qty) AS total_qty
    FROM expansion
    WHERE leaf_id NOT IN (SELECT DISTINCT packaging_id
                          FROM packaging_relations)
    GROUP BY packaging_id
)
SELECT
    AVG(total_qty) AS avg_total_leaf_quantity
FROM leaf_totals;