WITH RECURSIVE exploded(root_id, item_id, qty_mult) AS (
    -- start with every packaging that is never a child (top-level containers)
    SELECT pr.packaging_id,
           pr.contains_id,
           pr.qty
    FROM   packaging_relations AS pr
    WHERE  pr.packaging_id NOT IN (SELECT DISTINCT contains_id
                                   FROM   packaging_relations)

    UNION ALL
    -- walk down the hierarchy, multiplying the quantities along the way
    SELECT e.root_id,
           pr.contains_id,
           e.qty_mult * pr.qty
    FROM   exploded            AS e
    JOIN   packaging_relations AS pr
           ON pr.packaging_id = e.item_id
),
totals AS (
    SELECT root_id,
           item_id,
           SUM(qty_mult) AS total_qty
    FROM   exploded
    GROUP  BY root_id, item_id
    HAVING total_qty > 500            -- only those exceeding 500 in total
)
SELECT DISTINCT
       pc.name AS top_level_container,
       pi.name AS contained_item,
       totals.total_qty
FROM   totals
JOIN   packaging AS pc ON pc.id = totals.root_id
JOIN   packaging AS pi ON pi.id = totals.item_id;