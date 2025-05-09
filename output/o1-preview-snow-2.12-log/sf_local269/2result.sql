WITH RECURSIVE cte AS (
  -- Base case: start with top-level packaging_ids (final packaging combinations)
  SELECT
    pr."packaging_id" AS "top_packaging_id",
    pr."contains_id",
    CAST(pr."qty" AS FLOAT) AS "qty",
    CAST(pr."qty" AS FLOAT) AS "cumulative_qty"
  FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
  WHERE pr."packaging_id" IN (
    -- Identify final packaging combinations (not contained within any other packaging)
    SELECT p."id"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING p
    WHERE p."id" NOT IN (
      SELECT DISTINCT pr2."contains_id" FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr2
    )
  )
  UNION ALL
  -- Recursive case: expand nested packaging relationships
  SELECT
    cte."top_packaging_id",
    pr."contains_id",
    CAST(pr."qty" AS FLOAT),
    cte."cumulative_qty" * pr."qty" AS "cumulative_qty"
  FROM cte
  JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    ON cte."contains_id" = pr."packaging_id"
)
, totals AS (
  -- Calculate total quantity of leaf-level items for each final packaging combination
  SELECT
    cte."top_packaging_id",
    SUM(cte."cumulative_qty") AS "total_quantity"
  FROM cte
  WHERE cte."contains_id" NOT IN (
    -- Identify leaf-level items (items not containing any other items)
    SELECT DISTINCT pr."packaging_id" FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
  )
  GROUP BY cte."top_packaging_id"
)
-- Compute the average total quantity across all final packaging combinations
SELECT ROUND(AVG("total_quantity"), 4) AS "average_total_quantity"
FROM totals;