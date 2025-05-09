WITH RECURSIVE expl(root_id, contains_id, qty) AS (
    -- start with each direct relation
    SELECT  pr."packaging_id"  AS root_id,
            pr."contains_id",
            pr."qty"
    FROM    "packaging_relations" AS pr

    UNION ALL
    -- keep drilling down through any nested packaging
    SELECT  e."root_id",
            pr2."contains_id",
            e."qty" * pr2."qty"
    FROM    expl AS e
    JOIN    "packaging_relations" AS pr2
           ON pr2."packaging_id" = e."contains_id"
),
leaf_tot AS (
    -- keep only items that never act as a parent (true leaves)
    SELECT  e."root_id",
            SUM(e."qty") AS total_qty
    FROM    expl AS e
    LEFT JOIN "packaging_relations" AS nxt
           ON e."contains_id" = nxt."packaging_id"
    WHERE   nxt."packaging_id" IS NULL
    GROUP BY e."root_id"
)
SELECT AVG(total_qty) AS "average_total_leaf_qty"
FROM   leaf_tot;