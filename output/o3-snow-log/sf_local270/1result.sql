WITH RECURSIVE
/* 1. Top-level containers – those never listed as a contains_id */
top_containers AS (
    SELECT DISTINCT pr."packaging_id"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    WHERE pr."packaging_id" NOT IN (
          SELECT DISTINCT pr2."contains_id"
          FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr2 )
),

/* 2. Walk the hierarchy and accumulate quantities */
r AS (
    -- anchor: immediate children of every top-level container
    SELECT
        pr."packaging_id"  AS "top_container_id",
        pr."contains_id"   AS "child_id",
        pr."qty"           AS "edge_qty"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    JOIN top_containers tc
      ON tc."packaging_id" = pr."packaging_id"

    UNION ALL

    -- recursion: dive deeper while multiplying quantities
    SELECT
        r."top_container_id",
        pr2."contains_id",
        r."edge_qty" * pr2."qty"
    FROM r
    JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr2
      ON r."child_id" = pr2."packaging_id"
),

/* 3. Aggregate total quantity reaching each (top_container, item) pair */
aggregated AS (
    SELECT
        "top_container_id",
        "child_id",
        SUM("edge_qty") AS "total_qty"
    FROM r
    GROUP BY "top_container_id", "child_id"
    HAVING SUM("edge_qty") > 500            -- filter per requirement
)

/* 4. Attach readable names and present result */
SELECT
    tc."name"  AS "top_container_name",
    ci."name"  AS "child_item_name",
    a."total_qty"
FROM aggregated a
LEFT JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING tc
       ON tc."id" = a."top_container_id"
LEFT JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING ci
       ON ci."id" = a."child_id"
ORDER BY a."total_qty" DESC NULLS LAST;