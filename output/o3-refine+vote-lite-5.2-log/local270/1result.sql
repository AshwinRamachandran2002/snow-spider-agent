WITH RECURSIVE
/* top‑level containers: packages that are never themselves contained */
top_containers AS (
    SELECT p.id   AS container_id,
           p.name AS container_name
    FROM   packaging p
    WHERE  p.id IN (SELECT packaging_id FROM packaging_relations)      -- is a container
       AND p.id NOT IN (SELECT contains_id  FROM packaging_relations)  -- but never contained
),
/* walk the hierarchy, multiplying the quantities on the way down */
hierarchy AS (
    /* first level under the top container */
    SELECT tc.container_id,
           tc.container_name,
           pr.contains_id           AS item_id,
           pr.qty                   AS total_qty
    FROM   top_containers tc
    JOIN   packaging_relations pr
           ON pr.packaging_id = tc.container_id

    UNION ALL

    /* deeper levels */
    SELECT h.container_id,
           h.container_name,
           pr.contains_id,
           h.total_qty * pr.qty     AS total_qty
    FROM   hierarchy h
    JOIN   packaging_relations pr
           ON pr.packaging_id = h.item_id
),
/* sum any duplicate paths that reach the same item */
aggregated AS (
    SELECT container_id,
           item_id,
           SUM(total_qty) AS total_qty
    FROM   hierarchy
    GROUP  BY container_id, item_id
)
/* containers / items where the accumulated quantity exceeds 500 */
SELECT c.name AS container_name,
       i.name AS item_name
FROM   aggregated a
JOIN   packaging c ON c.id = a.container_id
JOIN   packaging i ON i.id = a.item_id
WHERE  a.total_qty > 500
ORDER  BY c.name,
          i.name;