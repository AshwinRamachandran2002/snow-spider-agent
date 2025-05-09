WITH filtered AS (
    SELECT 
        "state_name",
        COALESCE("total_assets", 0) AS "assets"
    FROM "FDA"."FDIC_BANKS"."INSTITUTIONS"
    WHERE "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
      AND "institution_name" ILIKE 'Bank%'
),
state_assets AS (
    SELECT 
        "state_name",
        SUM("assets") AS "total_assets"
    FROM filtered
    GROUP BY "state_name"
),
top_state AS (
    SELECT 
        "state_name"
    FROM state_assets
    ORDER BY "total_assets" DESC NULLS LAST
    LIMIT 1
),
state_counts AS (
    SELECT 
        "state_name",
        COUNT(*) AS "institution_count"
    FROM "FDA"."FDIC_BANKS"."INSTITUTIONS"
    GROUP BY "state_name"
)
SELECT 
    sc."institution_count"
FROM state_counts sc
JOIN top_state ts
  ON sc."state_name" = ts."state_name";