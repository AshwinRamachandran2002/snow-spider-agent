WITH RECURSIVE
    top_containers AS (                         -- containers that are never themselves “contained”
        SELECT DISTINCT pr."packaging_id"
        FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
        LEFT JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" ch
               ON pr."packaging_id" = ch."contains_id"
        WHERE ch."contains_id" IS NULL
    ),
    recursive_tree AS (                         -- walk the hierarchy from each top-level container
        /* anchor */
        SELECT  tc."packaging_id"      AS top_id,
                pr."contains_id",
                pr."qty"               AS multiplier
        FROM   top_containers tc
        JOIN   ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
               ON pr."packaging_id" = tc."packaging_id"
        UNION ALL
        /* recurse */
        SELECT  rt.top_id,
                pr."contains_id",
                rt.multiplier * pr."qty"   AS multiplier
        FROM   recursive_tree rt
        JOIN   ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
               ON pr."packaging_id" = rt."contains_id"
    )
SELECT   p_top."name"   AS "Top_Level_Container",
         p_item."name"  AS "Contained_Item"
FROM     recursive_tree rt
JOIN     ORACLE_SQL.ORACLE_SQL."PACKAGING" p_item
           ON p_item."id" = rt."contains_id"
JOIN     ORACLE_SQL.ORACLE_SQL."PACKAGING" p_top
           ON p_top."id" = rt.top_id
GROUP BY p_top."name", p_item."name"
HAVING   SUM(rt.multiplier) > 500               -- only items whose rolled-up quantity > 500
ORDER BY p_top."name", p_item."name";