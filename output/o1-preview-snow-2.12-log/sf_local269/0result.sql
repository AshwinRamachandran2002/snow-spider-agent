WITH cte AS (
  -- Anchor clause: start with top-level packaging items
  SELECT
    pr."packaging_id" AS "root_packaging_id",
    pr."contains_id",
    pr."qty" AS "total_qty"
  FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr
  WHERE pr."packaging_id" NOT IN (
    SELECT DISTINCT "contains_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
  )
  UNION ALL
  -- Recursive clause
  SELECT
    cte."root_packaging_id",
    pr."contains_id",
    cte."total_qty" * pr."qty" AS "total_qty"
  FROM cte
  JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr ON cte."contains_id" = pr."packaging_id"
)
SELECT AVG("total_quantity") AS "average_total_quantity"
FROM (
  SELECT "root_packaging_id", SUM("total_qty") AS "total_quantity"
  FROM (
    SELECT
      cte."root_packaging_id",
      cte."contains_id" AS "leaf_item_id",
      cte."total_qty"
    FROM cte
    WHERE cte."contains_id" NOT IN (
      SELECT DISTINCT "packaging_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
    )
  ) t_leaf
  GROUP BY "root_packaging_id"
) t_root;