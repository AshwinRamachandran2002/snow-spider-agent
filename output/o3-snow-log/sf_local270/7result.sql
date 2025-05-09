WITH RECURSIVE
/*------------------------------------------------------------------*/
/* 1)  Roots = containers that never appear as a child              */
root_ids AS (
    SELECT DISTINCT pr."packaging_id"
    FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
    WHERE pr."packaging_id" NOT IN (
          SELECT DISTINCT "contains_id"
          FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS"
          WHERE "contains_id" IS NOT NULL )
),
/*------------------------------------------------------------------*/
/* 2)  Recursive walk from each root down through all descendants   */
rec AS (
    /* seed level (root → direct child) */
    SELECT
        pr."packaging_id"      AS root_id,
        pr."contains_id"       AS node_id,
        CAST(pr."qty" AS FLOAT) AS cum_qty
    FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
    JOIN root_ids r
      ON r."packaging_id" = pr."packaging_id"

    UNION ALL

    /* recursive step (descend further) */
    SELECT
        rec.root_id,
        pr."contains_id",
        rec.cum_qty * pr."qty"
    FROM rec
    JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" pr
      ON pr."packaging_id" = rec.node_id
),
/*------------------------------------------------------------------*/
/* 3)  Keep only leaf rows (nodes that are never parents themselves)*/
leaf_paths AS (
    SELECT
        rec.root_id,
        rec.node_id    AS leaf_id,
        rec.cum_qty
    FROM rec
    WHERE rec.node_id NOT IN (
          SELECT DISTINCT "packaging_id"
          FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS" )
)
/*------------------------------------------------------------------*/
/* 4)  Display root containers & leaf items where cumulative qty>500*/
SELECT
    rp."name" AS "root_container_name",
    lp."name" AS "item_name"
FROM leaf_paths lpq
JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING" rp
  ON rp."id" = lpq.root_id
JOIN ORACLE_SQL.ORACLE_SQL."PACKAGING" lp
  ON lp."id" = lpq.leaf_id
WHERE lpq.cum_qty > 500
ORDER BY rp."name", lp."name";