WITH RECURSIVE
    -- Expand every packaging combination down to all of its descendants,
    -- keeping track of the running quantity (product of quantities on the path)
    expansion(parent_id, item_id, total_qty) AS (
        -- level‑0: the direct children of every packaging combination
        SELECT
            pr.packaging_id      AS parent_id,
            pr.contains_id       AS item_id,
            pr.qty               AS total_qty
        FROM packaging_relations pr

        UNION ALL
        
        -- deeper levels: keep expanding while the current item itself
        -- is used as a container for something else
        SELECT
            e.parent_id,
            pr.contains_id,
            e.total_qty * pr.qty   -- multiply quantities along the path
        FROM expansion e
        JOIN packaging_relations pr
              ON pr.packaging_id = e.item_id
    ),

    -- Identify the leaf‑level items (those that never act as a parent)
    leaf_totals AS (
        SELECT
            parent_id,
            SUM(total_qty) AS total_leaf_qty
        FROM expansion
        WHERE item_id NOT IN (SELECT DISTINCT packaging_id FROM packaging_relations)
        GROUP BY parent_id
    )

-- Average of the total leaf quantities across all packaging combinations
SELECT AVG(total_leaf_qty) AS average_total_quantity
FROM leaf_totals;