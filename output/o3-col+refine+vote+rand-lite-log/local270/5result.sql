WITH RECURSIVE pack_tree(top_id, item_id, qty_through_path) AS (
    /* level-0 : direct children of every top-level container */
    SELECT
        pr.packaging_id      AS top_id,
        pr.contains_id       AS item_id,
        pr.qty               AS qty_through_path
    FROM packaging_relations pr
    WHERE pr.packaging_id IN (          -- only true top-level containers
          SELECT p.id
          FROM   packaging p
          WHERE  p.id NOT IN (SELECT DISTINCT contains_id FROM packaging_relations)
    )

    UNION ALL

    /* level-n : walk further down the hierarchy */
    SELECT
        pt.top_id,
        pr.contains_id,
        pt.qty_through_path * pr.qty
    FROM   pack_tree         pt
    JOIN   packaging_relations pr
           ON pr.packaging_id = pt.item_id
)
/* containers & items whose accumulated quantity > 500 */
SELECT DISTINCT
       tp.name AS top_level_container,
       ip.name AS contained_item
FROM   pack_tree pt
JOIN   packaging tp ON tp.id = pt.top_id
JOIN   packaging ip ON ip.id = pt.item_id
GROUP  BY tp.name, ip.name
HAVING SUM(pt.qty_through_path) > 500;