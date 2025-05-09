WITH RECURSIVE
/* 1) find containers that are never children */
top AS ( 
    SELECT DISTINCT pr."packaging_id"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    WHERE pr."packaging_id" NOT IN (
          SELECT DISTINCT "contains_id"
          FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS )
),
/* 2) walk the hierarchy down from every top-level container */
r AS ( 
    /* anchor */
    SELECT
        pr."packaging_id",           -- top-level container
        pr."contains_id",            -- next level child
        pr."qty",
        pr."qty"      AS "path_multiplier"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    JOIN top t
      ON t."packaging_id" = pr."packaging_id"
    
    UNION ALL
    
    /* recursive part */
    SELECT
        pr2."packaging_id",          -- still the same top-level container
        pr2."contains_id",           -- deeper child
        pr2."qty",
        r."path_multiplier" * pr2."qty"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr2
    JOIN r
      ON pr2."packaging_id" = r."contains_id"
),
/* 3) accumulate total quantity per (top_container, item) pair */
agg AS ( 
    SELECT
        r."packaging_id"          AS "top_container_id",
        r."contains_id"           AS "item_id",
        SUM(r."path_multiplier")  AS "total_qty"
    FROM r
    GROUP BY r."packaging_id", r."contains_id"
    HAVING SUM(r."path_multiplier") > 500      -- only keep items >500
)
/* 4) final result with readable names */
SELECT
    pc."name"        AS "top_container_name",
    pi."name"        AS "item_name",
    a."total_qty"
FROM agg a
JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING pc
      ON pc."id" = a."top_container_id"
JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING pi
      ON pi."id" = a."item_id"
ORDER BY a."total_qty" DESC NULLS LAST;