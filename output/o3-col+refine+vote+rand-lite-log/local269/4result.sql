WITH RECURSIVE exp(root_id, contains_id, qty) AS (
    -- start with the direct parent-child relations
    SELECT
        packaging_id      AS root_id,
        contains_id,
        qty
    FROM packaging_relations

    UNION ALL

    -- expand down through any nested (child-as-parent) levels
    SELECT
        e.root_id,
        pr.contains_id,
        e.qty * pr.qty          -- propagate quantity multiplicatively
    FROM exp AS e
    JOIN packaging_relations AS pr
      ON pr.packaging_id = e.contains_id
),
leaf AS (
    -- keep only items that are never parents themselves (= true leaves)
    SELECT
        e.root_id,
        e.contains_id           AS leaf_id,
        SUM(e.qty)              AS leaf_qty
    FROM exp AS e
    LEFT JOIN packaging_relations AS chk
           ON chk.packaging_id = e.contains_id
    WHERE chk.packaging_id IS NULL
    GROUP BY e.root_id, e.contains_id
),
root_totals AS (
    -- total the leaf quantities for each root package
    SELECT
        root_id,
        SUM(leaf_qty) AS total_leaf_qty
    FROM leaf
    GROUP BY root_id
)
-- final average of those totals
SELECT ROUND(AVG(total_leaf_qty), 4) AS avg_total_leaf_qty
FROM root_totals;