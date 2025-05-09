WITH RECURSIVE rel AS (                        -- direct relationships
    SELECT
        "packaging_id",
        "contains_id",
        "qty"
    FROM ORACLE_SQL.ORACLE_SQL."PACKAGING_RELATIONS"
),
tops AS (                                      -- packages not contained in another
    SELECT DISTINCT "packaging_id"
    FROM rel
    WHERE "packaging_id" NOT IN (SELECT DISTINCT "contains_id" FROM rel)
),
expansion ( "packaging_id", "leaf_id", "mult_qty" ) AS (   -- walk the hierarchy
    ---------------------------------------------------------------------------
    -- first level below each top-level package
    SELECT
        r."packaging_id",
        r."contains_id"        AS "leaf_id",
        r."qty"                AS "mult_qty"
    FROM rel r
    JOIN tops t
      ON t."packaging_id" = r."packaging_id"

    UNION ALL
    ---------------------------------------------------------------------------
    -- continue down while multiplying quantities
    SELECT
        e."packaging_id",
        r."contains_id"        AS "leaf_id",
        e."mult_qty" * r."qty" AS "mult_qty"
    FROM expansion e
    JOIN rel r
      ON r."packaging_id" = e."leaf_id"
),
leaf_totals AS (                               -- total qty per top-level package
    SELECT
        "packaging_id",
        SUM("mult_qty") AS "total_qty"
    FROM expansion
    WHERE "leaf_id" NOT IN (SELECT DISTINCT "packaging_id" FROM rel)   -- true leaves
    GROUP BY "packaging_id"
)
SELECT AVG("total_qty") AS "avg_total_qty"     -- average across all packages
FROM leaf_totals;