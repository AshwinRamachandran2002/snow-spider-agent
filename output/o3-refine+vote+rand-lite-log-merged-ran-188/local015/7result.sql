WITH helmet_cases AS (
    SELECT 
        c."case_id",
        COALESCE(c."motorcyclist_killed_count",0) AS killed
    FROM "collisions" c
    WHERE c."motorcycle_collision" = 1
      AND EXISTS (
          SELECT 1
          FROM "parties" p
          WHERE p."case_id" = c."case_id"
            AND p."statewide_vehicle_type" LIKE '%motorcycle%'
            AND (p."party_safety_equipment_1" LIKE '%helmet%'
                 OR p."party_safety_equipment_2" LIKE '%helmet%')
      )
),
no_helmet_cases AS (
    SELECT 
        c."case_id",
        COALESCE(c."motorcyclist_killed_count",0) AS killed
    FROM "collisions" c
    WHERE c."motorcycle_collision" = 1
      AND NOT EXISTS (
          SELECT 1
          FROM "parties" p
          WHERE p."case_id" = c."case_id"
            AND p."statewide_vehicle_type" LIKE '%motorcycle%'
            AND (p."party_safety_equipment_1" LIKE '%helmet%'
                 OR p."party_safety_equipment_2" LIKE '%helmet%')
      )
),
helmet AS (
    SELECT COUNT(*) AS collisions,
           SUM(killed) AS fatalities
    FROM helmet_cases
),
no_helmet AS (
    SELECT COUNT(*) AS collisions,
           SUM(killed) AS fatalities
    FROM no_helmet_cases
)
SELECT 
    ROUND(100.0 * h.fatalities / h.collisions, 4) AS pct_fatal_helmet,
    ROUND(100.0 * n.fatalities / n.collisions, 4) AS pct_fatal_no_helmet
FROM helmet h, no_helmet n;