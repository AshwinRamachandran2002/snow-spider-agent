WITH fatal_motorcyclists AS (
    SELECT
      CASE
        WHEN 'driver, motorcycle helmet used' IN (v."victim_safety_equipment_1", v."victim_safety_equipment_2") OR
             'passenger, motorcycle helmet used' IN (v."victim_safety_equipment_1", v."victim_safety_equipment_2")
        THEN 'Helmeted'
        WHEN 'driver, motorcycle helmet not used' IN (v."victim_safety_equipment_1", v."victim_safety_equipment_2") OR
             'passenger, motorcycle helmet not used' IN (v."victim_safety_equipment_1", v."victim_safety_equipment_2")
        THEN 'Not Helmeted'
        ELSE 'Unknown'
      END AS "Helmet_use"
    FROM "victims" v
    JOIN "collisions" c ON v."case_id" = c."case_id"
    WHERE c."motorcycle_collision" = 1
      AND LOWER(v."victim_degree_of_injury") = 'killed'
      AND v."victim_role" IN ('driver', 'passenger')
)
SELECT
  "Helmet_use",
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fatal_motorcyclists WHERE "Helmet_use" != 'Unknown'), 4) AS "Percentage"
FROM fatal_motorcyclists
WHERE "Helmet_use" != 'Unknown'
GROUP BY "Helmet_use";