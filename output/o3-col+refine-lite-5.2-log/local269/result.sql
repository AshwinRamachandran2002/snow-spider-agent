WITH RECURSIVE expansion(packaging_id, leaf_id, qty) AS (
    -- start with every direct relation
    SELECT
        packaging_id,
        contains_id,
        qty
    FROM packaging_relations
    
    UNION ALL
    
    -- expand one nesting level at a time
    SELECT
        e.packaging_id,
        pr.contains_id,
        e.qty * pr.qty
    FROM expansion e
    JOIN packaging_relations pr
      ON e.leaf_id = pr.packaging_id
),
leaf_totals AS (
    -- keep only rows whose leaf_id is not itself a parent
    SELECT
        e.packaging_id,
        SUM(e.qty) AS total_leaf_qty
    FROM expansion e
    LEFT JOIN packaging_relations pr
      ON e.leaf_id = pr.packaging_id
    WHERE pr.packaging_id IS NULL          -- true leaves
    GROUP BY e.packaging_id
)
SELECT
    AVG(total_leaf_qty) AS avg_total_quantity
FROM leaf_totals;