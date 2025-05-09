WITH RECURSIVE
exp("packaging_id","leaf_id","qty") AS (
    -- first generation (direct children)
    SELECT "packaging_id","contains_id","qty"
    FROM "packaging_relations"
    UNION ALL
    -- recurse while the current leaf still appears as a parent
    SELECT e."packaging_id",
           pr."contains_id",
           e."qty" * pr."qty"
    FROM   exp e
    JOIN   "packaging_relations" pr
           ON pr."packaging_id" = e."leaf_id"
),
leaves AS (          -- items that never act as a parent
    SELECT DISTINCT "contains_id" AS "leaf_id"
    FROM   "packaging_relations"
    WHERE  "contains_id" NOT IN (SELECT "packaging_id" FROM "packaging_relations")
),
totals AS (          -- total qty of true leaves per top-level packaging
    SELECT e."packaging_id",
           SUM(e."qty") AS total_leaf_qty
    FROM   exp  e
    JOIN   leaves l ON e."leaf_id" = l."leaf_id"
    GROUP BY e."packaging_id"
)
SELECT AVG(total_leaf_qty) AS avg_total_leaf_qty
FROM   totals;