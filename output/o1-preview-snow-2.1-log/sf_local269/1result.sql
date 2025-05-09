WITH RecursivePackaging AS (
  SELECT
    p."id" as root_id,
    p."id" as item_id,
    1 as qty
  FROM ORACLE_SQL.ORACLE_SQL.PACKAGING p
  WHERE p."id" NOT IN (SELECT DISTINCT "contains_id" FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS)

  UNION ALL

  SELECT
    rp.root_id,
    pr."contains_id" as item_id,
    rp.qty * pr."qty" as qty
  FROM RecursivePackaging rp
  JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr
    ON rp.item_id = pr."packaging_id"
),

LeafItems AS (
  SELECT "id" FROM ORACLE_SQL.ORACLE_SQL.PACKAGING
  WHERE "id" NOT IN (SELECT DISTINCT "packaging_id" FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS)
),

TotalPerRoot AS (
  SELECT
    root_id,
    SUM(qty) as total_qty
  FROM RecursivePackaging rp
  WHERE rp.item_id IN (SELECT "id" FROM LeafItems)
  GROUP BY root_id
)

SELECT ROUND(AVG(total_qty), 4) as "average_total_quantity"
FROM TotalPerRoot;