WITH RECURSIVE
-- 1. top‑level (root) packaging combinations = those that never appear as a component
roots AS (
    SELECT DISTINCT pr.packaging_id
    FROM   packaging_relations pr
    WHERE  pr.packaging_id NOT IN (SELECT contains_id FROM packaging_relations)
),

-- 2. expand every root down to all its components, multiplying the quantities
tree(root_id, item_id, qty) AS (
    -- first level beneath each root
    SELECT pr.packaging_id, pr.contains_id, pr.qty
    FROM   packaging_relations pr
    JOIN   roots r ON r.packaging_id = pr.packaging_id
    UNION ALL
    -- deeper levels; multiply quantities along the path
    SELECT t.root_id,
           pr.contains_id,
           t.qty * pr.qty
    FROM   tree t
    JOIN   packaging_relations pr
           ON pr.packaging_id = t.item_id
),

-- 3. keep only the leaf‑level items (those that never act as a parent)
leaf_totals AS (
    SELECT root_id,
           SUM(qty) AS total_qty
    FROM   tree
    WHERE  item_id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
    GROUP BY root_id
)

-- 4. average of the total leaf quantities for every root packaging combination
SELECT AVG(total_qty) AS average_total_qty
FROM   leaf_totals;