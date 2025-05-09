WITH RECURSIVE expl(root_id, leaf_id, qty_mult) AS (
    -- start with each direct (parent → child) relation
    SELECT
        pr.packaging_id        AS root_id,
        pr.contains_id         AS leaf_id,
        pr.qty * 1.0           AS qty_mult          -- make sure it stays numeric/real
    FROM packaging_relations pr

    UNION ALL

    -- keep expanding while the current “leaf” is itself a parent
    SELECT
        e.root_id,
        pr.contains_id,
        e.qty_mult * pr.qty    -- multiply quantities along the path
    FROM expl e
    JOIN packaging_relations pr
      ON pr.packaging_id = e.leaf_id
),
leaf_totals AS (
    -- sum only true leaves (ones that never act as a parent)
    SELECT
        root_id,
        SUM(qty_mult) AS total_leaf_qty
    FROM expl
    WHERE leaf_id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
    GROUP BY root_id
)
SELECT
    AVG(total_leaf_qty) AS avg_total_leaf_qty
FROM leaf_totals;