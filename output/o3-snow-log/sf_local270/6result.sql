WITH RECURSIVE pkg_hier AS (
    /* Anchor: start with every container that is NOT itself contained in another package */
    SELECT
        pr."packaging_id"       AS "root_container",
        pr."contains_id"        AS "item_id",
        pr."qty"                AS "path_qty"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    WHERE pr."packaging_id" NOT IN (
        SELECT DISTINCT pr2."contains_id"
        FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr2
    )

    UNION ALL

    /* Recursive step: walk one level deeper and multiply quantities along the path */
    SELECT
        ph."root_container",
        pr2."contains_id",
        ph."path_qty" * pr2."qty" AS "path_qty"
    FROM pkg_hier ph
    JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr2
      ON pr2."packaging_id" = ph."item_id"
),

/* Sum the quantities for every (root-container, item) pair */
qty_sum AS (
    SELECT
        "root_container",
        "item_id",
        SUM("path_qty") AS "total_qty"
    FROM pkg_hier
    GROUP BY "root_container", "item_id"
    HAVING SUM("path_qty") > 500             -- only keep items whose total exceeds 500
)

/* Fetch human-readable names of containers and items */
SELECT DISTINCT
       c."name" AS "container_name",
       i."name" AS "item_name"
FROM qty_sum q
JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING c
  ON c."id" = q."root_container"
JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING i
  ON i."id" = q."item_id";