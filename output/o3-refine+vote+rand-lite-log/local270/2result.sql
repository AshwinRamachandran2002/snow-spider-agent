WITH RECURSIVE
/* 1. top‑level containers = packaging_ids that never appear as contains_id */
roots AS (
    SELECT DISTINCT pr.packaging_id AS root_id
    FROM   packaging_relations pr
    WHERE  pr.packaging_id NOT IN (SELECT contains_id FROM packaging_relations)
),

/* 2. walk the hierarchy, multiplying the quantities on the way down       */
rec AS (
    /* direct children of each root */
    SELECT pr.packaging_id  AS root_id,
           pr.contains_id   AS item_id,
           pr.qty           AS total_qty
    FROM   packaging_relations pr
    WHERE  pr.packaging_id IN (SELECT root_id FROM roots)

    UNION ALL

    /* deeper levels – keep multiplying the quantities */
    SELECT r.root_id,
           pr.contains_id,
           r.total_qty * pr.qty
    FROM   rec               AS r
    JOIN   packaging_relations pr
           ON pr.packaging_id = r.item_id
)

/* 3. aggregate per (root,item) and keep only those whose total exceeds 500 */
SELECT
       p_root.name AS container_name,
       p_item.name AS item_name
FROM (
        SELECT root_id,
               item_id,
               SUM(total_qty) AS total_qty
        FROM   rec
        GROUP  BY root_id, item_id
        HAVING SUM(total_qty) > 500
     ) AS x
JOIN   packaging AS p_root ON p_root.id = x.root_id
JOIN   packaging AS p_item ON p_item.id = x.item_id
ORDER  BY container_name,
          item_name;