WITH top_containers AS (       /* containers that are NOT inside any other container */
    SELECT p.id
    FROM packaging AS p
    LEFT JOIN packaging_relations AS pr
           ON pr.contains_id = p.id
    WHERE pr.contains_id IS NULL
),
recursive_tree AS (           /* walk the hierarchy and keep quantity multiplier */
    /* level‑1 children of each top‑level container */
    SELECT 
        tc.id            AS top_id,
        pr.contains_id   AS item_id,
        pr.qty           AS qty
    FROM top_containers AS tc
    JOIN packaging_relations AS pr
         ON pr.packaging_id = tc.id
    
    UNION ALL
    
    /* go deeper and multiply the quantities down the path */
    SELECT
        rt.top_id,
        pr.contains_id,
        rt.qty * pr.qty  AS qty
    FROM recursive_tree AS rt
    JOIN packaging_relations AS pr
         ON pr.packaging_id = rt.item_id
),
totals AS (                   /* total quantity per (top container , item) pair */
    SELECT
        top_id,
        item_id,
        SUM(qty) AS total_qty
    FROM recursive_tree
    GROUP BY top_id, item_id
    HAVING total_qty > 500     /* keep only the items whose total exceeds 500 */
)
SELECT
    p_top.name  AS container_name,
    p_item.name AS item_name
FROM totals
JOIN packaging AS p_top  ON p_top.id  = totals.top_id
JOIN packaging AS p_item ON p_item.id = totals.item_id
ORDER BY p_top.name,
         p_item.name;