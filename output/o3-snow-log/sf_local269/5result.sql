WITH RECURSIVE
-- start with every direct component of each packaging
cte AS (
    SELECT  pr."packaging_id"          AS root_id,
            pr."contains_id"           AS child_id,
            pr."qty"                   AS qty_mult
    FROM    ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    
    UNION ALL
    
    -- expand while the current child itself is a packaging that contains others
    SELECT  c.root_id,
            pr."contains_id"           AS child_id,
            c.qty_mult * pr."qty"      AS qty_mult
    FROM    cte                       c
    JOIN    ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
           ON c.child_id = pr."packaging_id"
),
-- keep only final leaf-level items (those that are never a parent)
leaf_expansion AS (
    SELECT  c.root_id,
            c.child_id        AS leaf_id,
            c.qty_mult
    FROM    cte               c
    WHERE   c.child_id NOT IN (
              SELECT DISTINCT "packaging_id"
              FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS
            )
),
-- total quantity of leaf items inside each top-level packaging
pack_totals AS (
    SELECT  root_id,
            SUM(qty_mult)     AS total_qty
    FROM    leaf_expansion
    GROUP BY root_id
)
-- average of those totals across all packaging combinations
SELECT  AVG(total_qty) AS avg_total_leaf_quantity
FROM    pack_totals;