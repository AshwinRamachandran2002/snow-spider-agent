/*  Fatality-rate (%) for motorcycle collisions, split by helmet use  */
WITH helmet_collisions AS (
    SELECT DISTINCT p."case_id"
    FROM   "parties" AS p
    WHERE  p."statewide_vehicle_type" LIKE '%motorcycle%'
           AND (p."party_safety_equipment_1" LIKE '%helmet%used%'
                OR p."party_safety_equipment_2" LIKE '%helmet%used%')
),
no_helmet_collisions AS (
    SELECT DISTINCT p."case_id"
    FROM   "parties" AS p
    WHERE  p."statewide_vehicle_type" LIKE '%motorcycle%'
           AND (p."party_safety_equipment_1" LIKE '%helmet%not%'
                OR p."party_safety_equipment_2" LIKE '%helmet%not%'
                OR (p."party_safety_equipment_1" IS NULL
                    AND p."party_safety_equipment_2" IS NULL))
),
helmet_stats AS (
    SELECT COUNT(*)                                   AS total_collisions,
           COALESCE(SUM(c."motorcyclist_killed_count"),0) AS total_killed
    FROM   helmet_collisions hc
    JOIN   "collisions" c  ON c."case_id" = hc."case_id"
),
no_helmet_stats AS (
    SELECT COUNT(*)                                   AS total_collisions,
           COALESCE(SUM(c."motorcyclist_killed_count"),0) AS total_killed
    FROM   no_helmet_collisions nhc
    JOIN   "collisions" c  ON c."case_id" = nhc."case_id"
)
SELECT
  ROUND(100.0 * hs.total_killed / hs.total_collisions, 4)  AS helmet_fatality_rate_pct,
  ROUND(100.0 * nhs.total_killed / nhs.total_collisions, 4) AS no_helmet_fatality_rate_pct
FROM helmet_stats hs, no_helmet_stats nhs;