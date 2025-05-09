WITH RECURSIVE
-- expand every packaging combination down to the leaves
expand(root_packaging_id , current_id , qty_mult) AS (
    /* direct children of every packaging combination          */
    SELECT pr.packaging_id         AS root_packaging_id ,
           pr.contains_id          AS current_id ,
           pr.qty * 1.0            AS qty_mult
    FROM   packaging_relations pr

    UNION ALL

    /* keep drilling down while the current item itself
       contains other items                                    */
    SELECT e.root_packaging_id ,
           pr.contains_id ,
           e.qty_mult * pr.qty
    FROM   expand              e
    JOIN   packaging_relations pr
           ON pr.packaging_id = e.current_id
),

/* keep only the leaf‑level items (those that do not act as a parent) */
leaves AS (
    SELECT root_packaging_id ,
           current_id  AS leaf_item_id ,
           qty_mult    AS qty
    FROM   expand
    WHERE  current_id NOT IN (SELECT DISTINCT packaging_id
                              FROM   packaging_relations)
),

/* total quantity of leaf items inside each top‑level packaging */
totals AS (
    SELECT root_packaging_id ,
           SUM(qty) AS total_leaf_qty
    FROM   leaves
    GROUP BY root_packaging_id
)

/* average of those totals */
SELECT AVG(total_leaf_qty) AS avg_total_leaf_qty
FROM   totals;