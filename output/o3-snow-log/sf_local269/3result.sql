WITH RECURSIVE rel ("packaging_id","contains_id","qty") AS (          -- base parent-child rows
    SELECT 
        "packaging_id",
        "contains_id",
        "qty"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS
), 
expansion (root_id , leaf_id , path_qty) AS (                         -- expand through all levels
    SELECT                                                            -- level-1
        "packaging_id" AS root_id,
        "contains_id"  AS leaf_id,
        "qty"          AS path_qty
    FROM rel
    UNION ALL                                                         -- deeper levels
    SELECT
        e.root_id,
        r."contains_id",
        e.path_qty * r."qty"
    FROM expansion e
    JOIN rel r
      ON e.leaf_id = r."packaging_id"
), 
leaves AS (                                                           -- rows that are not further split
    SELECT 
        root_id,
        leaf_id,
        path_qty
    FROM expansion
    WHERE leaf_id NOT IN (SELECT DISTINCT "packaging_id" FROM rel)
), 
totals AS (                                                           -- total quantity per root package
    SELECT 
        root_id,
        SUM(path_qty) AS total_leaf_qty
    FROM leaves
    GROUP BY root_id
)
SELECT                                                                 -- average of all totals
    AVG(total_leaf_qty) AS avg_total_leaf_qty
FROM totals;