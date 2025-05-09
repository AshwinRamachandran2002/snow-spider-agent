WITH RECURSIVE pack_hierarchy(top_id, item_id, total_qty) AS (
    /* level-0 : direct children of each top-level container */
    SELECT pr.packaging_id  AS top_id,
           pr.contains_id   AS item_id,
           pr.qty           AS total_qty
    FROM   packaging_relations pr
    WHERE  pr.packaging_id NOT IN (SELECT contains_id FROM packaging_relations)

    UNION ALL

    /* deeper levels : keep descending as long as the child is itself a container */
    SELECT ph.top_id,
           pr.contains_id,
           ph.total_qty * pr.qty
    FROM   pack_hierarchy      ph
    JOIN   packaging_relations pr
           ON pr.packaging_id = ph.item_id
)
/* aggregate the quantities per (top-level, nested-item) pair
   and keep only those whose summed quantity exceeds 500         */
SELECT DISTINCT tp.name AS top_level_container,
       ti.name AS nested_item_exceeding_500
FROM   (
        SELECT top_id,
               item_id,
               SUM(total_qty) AS total_qty
        FROM   pack_hierarchy
        GROUP  BY top_id, item_id
        HAVING SUM(total_qty) > 500
       ) big
JOIN   packaging tp ON tp.id = big.top_id
JOIN   packaging ti ON ti.id = big.item_id
ORDER  BY tp.name,
          ti.name;