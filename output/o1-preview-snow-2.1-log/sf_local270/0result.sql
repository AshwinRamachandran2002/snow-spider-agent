WITH RECURSIVE packaging_totals AS (
    SELECT pr."packaging_id", pr."contains_id", pr."qty"
    FROM ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr

    UNION ALL

    SELECT pt."packaging_id", pr."contains_id", pt."qty" * pr."qty"
    FROM packaging_totals pt
    JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING_RELATIONS pr ON pt."contains_id" = pr."packaging_id"
)
SELECT pt."packaging_id", p."name", SUM(pt."qty") AS "total_quantity"
FROM packaging_totals pt
JOIN ORACLE_SQL.ORACLE_SQL.PACKAGING p ON pt."packaging_id" = p."id"
GROUP BY pt."packaging_id", p."name"
HAVING SUM(pt."qty") > 500;