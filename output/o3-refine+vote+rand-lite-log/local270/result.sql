WITH RECURSIVE
/* 1. top‑level containers = appear as packaging_id but never as contains_id */
top_level AS (
    SELECT DISTINCT pr.packaging_id   AS id
    FROM   packaging_relations pr
    WHERE  pr.packaging_id NOT IN (SELECT contains_id FROM packaging_relations)
),
/* 2. walk the hierarchy and accumulate the multiplied quantities      */
hierarchy AS (
    /* direct children of every top‑level container */
    SELECT
        pr.packaging_id            AS root_id,      -- fixed top container
        pr.contains_id             AS item_id,      -- current item below it
        pr.qty                     AS qty           -- quantity so far
    FROM   packaging_relations pr
    WHERE  pr.packaging_id IN (SELECT id FROM top_level)

    UNION ALL

    /* deeper levels: multiply quantities along the path */
    SELECT
        h.root_id,
        pr.contains_id,
        h.qty * pr.qty
    FROM   hierarchy h
    JOIN   packaging_relations pr
           ON pr.packaging_id = h.item_id           -- the current item is itself a container
)
/* 3. sum per (root container , item) and keep those above 500 */
SELECT
    pc.name  AS container_name,
    pi.name  AS item_name
FROM (
    SELECT
        root_id,
        item_id,
        SUM(qty) AS total_qty
    FROM   hierarchy
    GROUP  BY root_id, item_id
    HAVING total_qty > 500
) q
JOIN packaging pc ON pc.id = q.root_id
JOIN packaging pi ON pi.id = q.item_id
ORDER BY pc.name,
         pi.name;