WITH helmet_parties AS (
    SELECT
        c."case_id",
        c."motorcyclist_killed_count",
        CASE
            WHEN LOWER(COALESCE(p."party_safety_equipment_1",'')) LIKE '%helmet%used%'
              OR LOWER(COALESCE(p."party_safety_equipment_2",'')) LIKE '%helmet%used%'
            THEN 'helmet_used'
            WHEN LOWER(COALESCE(p."party_safety_equipment_1",'')) LIKE '%helmet%not%used%'
              OR LOWER(COALESCE(p."party_safety_equipment_2",'')) LIKE '%helmet%not%used%'
            THEN 'helmet_not_used'
        END AS "helmet_usage"
    FROM "collisions" AS c
    JOIN "parties"     AS p
         ON c."case_id" = p."case_id"
    WHERE p."statewide_vehicle_type" LIKE '%motorcycle%'
      AND (LOWER(COALESCE(p."party_safety_equipment_1",'')) LIKE '%helmet%'
           OR LOWER(COALESCE(p."party_safety_equipment_2",'')) LIKE '%helmet%')
),
agg AS (
    SELECT
        "helmet_usage",
        COUNT(DISTINCT "case_id")              AS "collision_count",
        SUM("motorcyclist_killed_count")       AS "fatalities"
    FROM helmet_parties
    WHERE "helmet_usage" IS NOT NULL
    GROUP BY "helmet_usage"
)
SELECT
    "helmet_usage",
    ROUND(100.0 * "fatalities" / "collision_count", 4) AS "fatality_rate_percent"
FROM agg;