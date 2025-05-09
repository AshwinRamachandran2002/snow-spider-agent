WITH RECURSIVE cte(packaging_id, packaging_name, contains_id, total_qty) AS (
  SELECT
    pr.packaging_id,
    p.name AS packaging_name,
    pr.contains_id,
    pr.qty
  FROM
    packaging_relations pr
    JOIN packaging p ON pr.packaging_id = p.id

  UNION ALL

  SELECT
    cte.packaging_id,
    cte.packaging_name,
    pr.contains_id,
    cte.total_qty * pr.qty
  FROM
    cte
    JOIN packaging_relations pr ON cte.contains_id = pr.packaging_id
)
SELECT
  packaging_id,
  packaging_name,
  SUM(total_qty) AS total_quantity
FROM
  cte
GROUP BY
  packaging_id,
  packaging_name
HAVING
  SUM(total_qty) > 500;