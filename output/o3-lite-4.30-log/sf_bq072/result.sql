WITH ages(age) AS (
    SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL
    SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18
),
vehicle_deaths AS (
    SELECT
        dr."Age"                         AS age,
        COUNT(DISTINCT dr."Id")          AS total_vehicle_deaths
    FROM DEATH.DEATH."DEATHRECORDS"         dr
    JOIN DEATH.DEATH."ENTITYAXISCONDITIONS" ec
      ON ec."DeathRecordId" = dr."Id"
    JOIN DEATH.DEATH."ICD10CODE"            ic
      ON ic."Code" = ec."Icd10Code"
    WHERE dr."Age" BETWEEN 12 AND 18
      AND ic."Description" ILIKE '%vehicle%'
    GROUP BY dr."Age"
),
vehicle_black_deaths AS (
    SELECT
        dr."Age"                         AS age,
        COUNT(DISTINCT dr."Id")          AS black_vehicle_deaths
    FROM DEATH.DEATH."DEATHRECORDS"         dr
    JOIN DEATH.DEATH."ENTITYAXISCONDITIONS" ec
      ON ec."DeathRecordId" = dr."Id"
    JOIN DEATH.DEATH."ICD10CODE"            ic
      ON ic."Code" = ec."Icd10Code"
    JOIN DEATH.DEATH."RACE"                 r
      ON r."Code" = dr."Race"
    WHERE dr."Age" BETWEEN 12 AND 18
      AND ic."Description" ILIKE '%vehicle%'
      AND r."Description" ILIKE '%black%'
    GROUP BY dr."Age"
),
firearm_deaths AS (
    SELECT
        dr."Age"                         AS age,
        COUNT(DISTINCT dr."Id")          AS total_firearm_deaths
    FROM DEATH.DEATH."DEATHRECORDS"         dr
    JOIN DEATH.DEATH."ENTITYAXISCONDITIONS" ec
      ON ec."DeathRecordId" = dr."Id"
    JOIN DEATH.DEATH."ICD10CODE"            ic
      ON ic."Code" = ec."Icd10Code"
    WHERE dr."Age" BETWEEN 12 AND 18
      AND ic."Description" ILIKE '%firearm%'
    GROUP BY dr."Age"
),
firearm_black_deaths AS (
    SELECT
        dr."Age"                         AS age,
        COUNT(DISTINCT dr."Id")          AS black_firearm_deaths
    FROM DEATH.DEATH."DEATHRECORDS"         dr
    JOIN DEATH.DEATH."ENTITYAXISCONDITIONS" ec
      ON ec."DeathRecordId" = dr."Id"
    JOIN DEATH.DEATH."ICD10CODE"            ic
      ON ic."Code" = ec."Icd10Code"
    JOIN DEATH.DEATH."RACE"                 r
      ON r."Code" = dr."Race"
    WHERE dr."Age" BETWEEN 12 AND 18
      AND ic."Description" ILIKE '%firearm%'
      AND r."Description" ILIKE '%black%'
    GROUP BY dr."Age"
)
SELECT
    a.age,
    COALESCE(v.total_vehicle_deaths, 0)  AS total_vehicle_deaths,
    COALESCE(vb.black_vehicle_deaths, 0) AS black_vehicle_deaths,
    COALESCE(f.total_firearm_deaths, 0)  AS total_firearm_deaths,
    COALESCE(fb.black_firearm_deaths, 0) AS black_firearm_deaths
FROM ages a
LEFT JOIN vehicle_deaths       v  ON v.age  = a.age
LEFT JOIN vehicle_black_deaths vb ON vb.age = a.age
LEFT JOIN firearm_deaths       f  ON f.age  = a.age
LEFT JOIN firearm_black_deaths fb ON fb.age = a.age
ORDER BY a.age;