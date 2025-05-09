WITH RECURSIVE
    "TOP_LEVEL" AS (      -- packages that are never contained by another package
        SELECT DISTINCT pr."packaging_id"
        FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
        WHERE pr."packaging_id" NOT IN (
              SELECT DISTINCT pr2."contains_id"
              FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr2
        )
    ),
    "R" AS (              -- walk the hierarchy and accumulate quantities
        /* first level below every top-level container */
        SELECT  pr."packaging_id"      AS "top_pkg_id",
                pr."contains_id",
                pr."qty"               AS "qty"
        FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
        JOIN "TOP_LEVEL" tl
          ON tl."packaging_id" = pr."packaging_id"

        UNION ALL
        /* deeper levels */
        SELECT  r."top_pkg_id",
                pr2."contains_id",
                r."qty" * pr2."qty"    AS "qty"
        FROM "R" r
        JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr2
              ON pr2."packaging_id" = r."contains_id"
    )
SELECT  r."top_pkg_id"                                 AS "TOP_CONTAINER_ID",
        p_top."name"                                   AS "TOP_CONTAINER_NAME",
        r."contains_id"                                AS "ITEM_ID",
        COALESCE(p_item."name", '(no name)')           AS "ITEM_NAME",
        SUM(r."qty")                                   AS "TOTAL_QTY"
FROM "R" r
LEFT JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING"  p_top
       ON p_top."id" = r."top_pkg_id"
LEFT JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING"  p_item
       ON p_item."id" = r."contains_id"
GROUP BY r."top_pkg_id",
         p_top."name",
         r."contains_id",
         p_item."name"
HAVING SUM(r."qty") > 500
ORDER BY "TOTAL_QTY" DESC NULLS LAST,
         "TOP_CONTAINER_ID",
         "ITEM_ID";