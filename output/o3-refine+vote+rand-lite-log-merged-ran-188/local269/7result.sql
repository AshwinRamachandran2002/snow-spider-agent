WITH RECURSIVE
    -- all packaging IDs that act as parents (root combinations)
    parents(root_id) AS (
        SELECT DISTINCT packaging_id
        FROM packaging_relations
    ),

    -- recursively break each root combination down to its leaves,
    -- keeping a running multiplier of quantities along the path
    expand(item_id, root_id, qty_mult) AS (
        -- first level (direct children of each root package)
        SELECT pr.contains_id,
               pr.packaging_id   AS root_id,
               pr.qty            AS qty_mult
        FROM   packaging_relations pr

        UNION ALL

        -- deeper levels (child is itself a package that contains others)
        SELECT pr.contains_id,
               e.root_id,
               e.qty_mult * pr.qty        -- multiply quantities down the path
        FROM   expand e
        JOIN   packaging_relations pr
               ON pr.packaging_id = e.item_id
    ),

    -- total quantity of true leaf items for every root package
    leaf_totals AS (
        SELECT  e.root_id,
                SUM(e.qty_mult) AS total_qty
        FROM    expand e
        LEFT JOIN (SELECT DISTINCT packaging_id FROM packaging_relations) p
               ON e.item_id = p.packaging_id      -- p≠NULL ⇒ item is a parent
        WHERE   p.packaging_id IS NULL            -- keep only leaf items
        GROUP BY e.root_id
    )

-- average of those total leaf quantities across all root combinations
SELECT AVG(total_qty) AS avg_total_quantity
FROM   leaf_totals;