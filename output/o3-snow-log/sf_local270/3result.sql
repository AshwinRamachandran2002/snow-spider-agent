/*-------------------------------------------------------------
  Which top-level packaging containers (i.e. packages that are
  not themselves contained inside any other package) have at
  least one contained item whose total quantity – after walking
  all levels of the hierarchy – exceeds 500?
-------------------------------------------------------------*/
WITH
/* 1) Top-level packages : never found as a “contains_id”       */
"TOP_PKGS" AS (
    SELECT DISTINCT pr1."packaging_id" AS "pkg_id"
    FROM   ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr1
    LEFT   JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr2
           ON pr2."contains_id" = pr1."packaging_id"
    WHERE  pr2."packaging_id" IS NULL
),

/* 2) Walk the package-inside-package hierarchy recursively     */
"PKG_TREE" AS (
        /* level-0 : direct children of each top-level package */
        SELECT  pr."packaging_id"               AS "root_pkg_id",
                pr."contains_id"                AS "item_id",
                CAST(pr."qty" AS FLOAT)         AS "qty_mult"
        FROM    ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
        JOIN    "TOP_PKGS" t
               ON t."pkg_id" = pr."packaging_id"

        UNION ALL

        /* level-n : keep descending as long as the current
                     child is itself a package that contains
                     something further                                     */
        SELECT  pt."root_pkg_id",
                pr2."contains_id",
                pt."qty_mult" * pr2."qty"
        FROM    "PKG_TREE"                        pt
        JOIN    ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr2
               ON pr2."packaging_id" = pt."item_id"
),

/* 3) Aggregate the multiplied quantities for every
      (top-level package, contained item) pair                   */
"AGG" AS (
    SELECT  "root_pkg_id",
            "item_id",
            SUM("qty_mult") AS "total_qty"
    FROM    "PKG_TREE"
    GROUP BY "root_pkg_id",
             "item_id"
)

/* 4) Return only those combinations where total_qty > 500,
      plus the human-readable names of both the container
      and the contained item                                     */
SELECT  rp."name"                           AS "top_level_container",
        ip."name"                           AS "contained_item",
        a."total_qty"
FROM    "AGG"                               a
JOIN    ORACLE_SQL.ORACLE_SQL."PACKAGING"   rp ON rp."id" = a."root_pkg_id"
JOIN    ORACLE_SQL.ORACLE_SQL."PACKAGING"   ip ON ip."id" = a."item_id"
WHERE   a."total_qty" > 500
ORDER BY rp."name",
         ip."name";