WITH RECURSIVE bom(packaging_id, leaf_id, qty) AS (
    -- direct parent ➜ child relations
    SELECT
        pr.packaging_id,
        pr.contains_id,
        pr.qty
    FROM packaging_relations pr

    UNION ALL

    -- keep drilling down while the current "leaf" still contains sub-items
    SELECT
        b.packaging_id,
        pr.contains_id,
        b.qty * pr.qty
    FROM bom b
    JOIN packaging_relations pr
      ON pr.packaging_id = b.leaf_id
),
leaf_only AS (
    -- keep only true leaves (never appear as a parent)
    SELECT
        packaging_id,
        leaf_id,
        qty
    FROM bom
    WHERE leaf_id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
),
totals AS (
    -- total leaf quantity per top-level package
    SELECT
        packaging_id,
        SUM(qty) AS total_leaf_qty
    FROM leaf_only
    GROUP BY packaging_id
)
-- overall average of those totals
SELECT
    AVG(total_leaf_qty) AS average_total_leaf_qty
FROM totals;