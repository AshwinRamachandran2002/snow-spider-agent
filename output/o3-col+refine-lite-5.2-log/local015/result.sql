WITH
-- collisions that include at least one motorcyclist (driver or passenger) who WAS wearing a helmet
helmeted_collisions AS (
    SELECT DISTINCT p."case_id"
    FROM "parties" p
    WHERE p."statewide_vehicle_type" LIKE '%motor%'
      AND (
            (p."party_safety_equipment_1" LIKE '%helmet%'  AND p."party_safety_equipment_1" NOT LIKE '%not%')
         OR (p."party_safety_equipment_2" LIKE '%helmet%'  AND p."party_safety_equipment_2" NOT LIKE '%not%')
      )
),

-- collisions that include at least one motorcyclist who was NOT wearing a helmet
non_helmeted_collisions AS (
    SELECT DISTINCT p."case_id"
    FROM "parties" p
    WHERE p."statewide_vehicle_type" LIKE '%motor%'
      AND (
            p."party_safety_equipment_1" LIKE '%helmet not used%'
         OR p."party_safety_equipment_2" LIKE '%helmet not used%'
      )
),

-- aggregate deaths, collisions, and compute fatality rate for each group
stats AS (
    SELECT 'helmet worn' AS group_type,
           SUM(c."motorcyclist_killed_count") AS deaths,
           COUNT(*)                           AS collisions
    FROM "collisions" c
    WHERE c."case_id" IN (SELECT "case_id" FROM helmeted_collisions)

    UNION ALL

    SELECT 'helmet not worn',
           SUM(c."motorcyclist_killed_count"),
           COUNT(*)
    FROM "collisions" c
    WHERE c."case_id" IN (SELECT "case_id" FROM non_helmeted_collisions)
)

SELECT  group_type,
        deaths,
        collisions,
        ROUND(100.0 * deaths / collisions, 2) AS fatality_rate_percent
FROM stats;