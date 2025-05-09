WITH RECURSIVE
-- all packagings that themselves contain something
containers AS (
    SELECT DISTINCT packaging_id FROM packaging_relations
),

-- recursively explode every packaging down to its leaf items,
-- multiplying the quantities along the way
tree AS (
    -- direct children
    SELECT
        pr.packaging_id          AS root_pack,
        pr.contains_id           AS item_id,
        pr.qty                   AS qty
    FROM packaging_relations pr

    UNION ALL

    -- go one level deeper whenever the current item is itself a container
    SELECT
        t.root_pack,
        pr.contains_id,
        t.qty * pr.qty
    FROM tree t
    JOIN packaging_relations pr
          ON pr.packaging_id = t.item_id
)

-- aggregate to total leaf quantity for each top‑level packaging,
-- then take the average of those totals
SELECT AVG(total_qty) AS avg_total_leaf_qty
FROM (
    SELECT
        root_pack,
        SUM(qty) AS total_qty
    FROM tree
    -- keep only leaf items (those that never act as a container)
    WHERE item_id NOT IN (SELECT packaging_id FROM containers)
    GROUP BY root_pack
) AS per_pack;