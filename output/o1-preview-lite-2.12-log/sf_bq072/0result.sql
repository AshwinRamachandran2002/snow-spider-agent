WITH death_conditions AS (
  SELECT
    dr."Id",
    dr."Age",
    r."Description" AS RaceDescription,
    MAX(CASE WHEN icd."Description" ILIKE '%vehicle%' THEN 1 ELSE 0 END) AS is_vehicle,
    MAX(CASE WHEN icd."Description" ILIKE '%firearm%' THEN 1 ELSE 0 END) AS is_firearm
  FROM "DEATH"."DEATH"."DEATHRECORDS" dr
  JOIN "DEATH"."DEATH"."ENTITYAXISCONDITIONS" eac ON dr."Id" = eac."DeathRecordId"
  JOIN "DEATH"."DEATH"."ICD10CODE" icd ON eac."Icd10Code" = icd."Code"
  LEFT JOIN "DEATH"."DEATH"."RACE" r ON dr."Race" = r."Code"
  WHERE dr."Age" BETWEEN 12 AND 18
  GROUP BY dr."Id", dr."Age", r."Description"
)
SELECT
  "Age",
  SUM(CASE WHEN is_vehicle = 1 THEN 1 ELSE 0 END) AS TotalDeaths_Vehicle,
  SUM(CASE WHEN is_vehicle = 1 AND RaceDescription ILIKE '%black%' THEN 1 ELSE 0 END) AS BlackDeaths_Vehicle,
  SUM(CASE WHEN is_firearm = 1 THEN 1 ELSE 0 END) AS TotalDeaths_Firearm,
  SUM(CASE WHEN is_firearm = 1 AND RaceDescription ILIKE '%black%' THEN 1 ELSE 0 END) AS BlackDeaths_Firearm
FROM death_conditions
GROUP BY "Age"
ORDER BY "Age";