WITH
-- Motorcycle–party rows, classed by helmet usage -----------------------------
helmet_yes AS (                 -- at least one motor-cyclist *wearing* a helmet
    SELECT DISTINCT p."case_id"
    FROM "parties"    p
    JOIN "collisions" c ON c."case_id" = p."case_id"
    WHERE c."motorcycle_collision" = 1
      AND p."statewide_vehicle_type"      LIKE '%motorcycle%'
      AND (p."party_safety_equipment_1"   LIKE '%helmet%'
           OR p."party_safety_equipment_2" LIKE '%helmet%')
),
helmet_no AS (                  -- at least one motor-cyclist *not* wearing a helmet
    SELECT DISTINCT p."case_id"
    FROM "parties"    p
    JOIN "collisions" c ON c."case_id" = p."case_id"
    WHERE c."motorcycle_collision" = 1
      AND p."statewide_vehicle_type"      LIKE '%motorcycle%'
      AND (p."party_safety_equipment_1"   LIKE '%helmet not used%'
           OR p."party_safety_equipment_2" LIKE '%helmet not used%')
)
SELECT
    100.0 * (
        SELECT IFNULL(SUM(c."motorcyclist_killed_count"),0)
        FROM   "collisions" c
        WHERE  c."case_id" IN (SELECT "case_id" FROM helmet_yes)
    ) / NULLIF((SELECT COUNT(*) FROM helmet_yes),0)   AS "fatality_rate_helmet_yes",
    100.0 * (
        SELECT IFNULL(SUM(c."motorcyclist_killed_count"),0)
        FROM   "collisions" c
        WHERE  c."case_id" IN (SELECT "case_id" FROM helmet_no)
    ) / NULLIF((SELECT COUNT(*) FROM helmet_no),0)    AS "fatality_rate_helmet_no";