WITH "discharge_counts" AS (   -- deaths with “discharge” (excluding the 3 unwanted phrases)
    SELECT
        d."AgeRecode27",
        COUNT(*) AS "death_cnt"
    FROM DEATH.DEATH."DEATHRECORDS"  d
    JOIN DEATH.DEATH."ICD10CODE"     c
          ON d."Icd10Code" = c."Code"
    WHERE d."RaceRecode3" = 1                       -- White
      AND c."Description" ILIKE '%discharge%'
      AND c."Description" NOT ILIKE '%urethral%discharge%'
      AND c."Description" NOT ILIKE '%firework%discharge%'
      AND c."Description" NOT ILIKE '%firearm%discharge%'
    GROUP BY d."AgeRecode27"
),
"vehicle_counts" AS (          -- deaths with “vehicle”
    SELECT
        d."AgeRecode27",
        COUNT(*) AS "death_cnt"
    FROM DEATH.DEATH."DEATHRECORDS"  d
    JOIN DEATH.DEATH."ICD10CODE"     c
          ON d."Icd10Code" = c."Code"
    WHERE d."RaceRecode3" = 1                       -- White
      AND c."Description" ILIKE '%vehicle%'
    GROUP BY d."AgeRecode27"
)
SELECT
    ROUND((SELECT AVG("death_cnt") FROM "discharge_counts"), 4) AS "avg_deaths_discharge",
    ROUND((SELECT AVG("death_cnt") FROM "vehicle_counts"), 4)   AS "avg_deaths_vehicle",
    ROUND((SELECT AVG("death_cnt") FROM "discharge_counts")
        - (SELECT AVG("death_cnt") FROM "vehicle_counts"), 4)   AS "difference_discharge_minus_vehicle";