WITH discharge_agg AS (           -- deaths whose ICD-10 description contains “discharge” (with exclusions)
    SELECT d."AgeRecode12",
           COUNT(*) AS "death_cnt"
    FROM   DEATH.DEATH.DEATHRECORDS  d
    JOIN   DEATH.DEATH.ICD10CODE     ic
           ON d."Icd10Code" = ic."Code"
    WHERE  d."RaceRecode3" = 1                       -- White
      AND  ic."Description" ILIKE '%discharge%'
      AND  ic."Description" NOT ILIKE '%urethral discharge%'
      AND  ic."Description" NOT ILIKE '%discharge of firework%'
      AND  ic."Description" NOT ILIKE '%legal intervention involving firearm discharge%'
    GROUP  BY d."AgeRecode12"
),
vehicle_agg AS (             -- deaths whose ICD-10 description contains “vehicle”
    SELECT d."AgeRecode12",
           COUNT(*) AS "death_cnt"
    FROM   DEATH.DEATH.DEATHRECORDS  d
    JOIN   DEATH.DEATH.ICD10CODE     ic
           ON d."Icd10Code" = ic."Code"
    WHERE  d."RaceRecode3" = 1                       -- White
      AND  ic."Description" ILIKE '%vehicle%'
    GROUP  BY d."AgeRecode12"
),
combined AS (                -- align the two sets by age-group, filling missing counts with 0
    SELECT COALESCE(d."AgeRecode12", v."AgeRecode12")      AS "AgeRecode12",
           COALESCE(d."death_cnt", 0)                      AS "discharge_deaths",
           COALESCE(v."death_cnt", 0)                      AS "vehicle_deaths"
    FROM   discharge_agg d
    FULL  OUTER JOIN vehicle_agg v
           ON d."AgeRecode12" = v."AgeRecode12"
)
SELECT AVG("discharge_deaths")                              AS "avg_discharge_deaths",
       AVG("vehicle_deaths")                                AS "avg_vehicle_deaths",
       AVG("discharge_deaths") - AVG("vehicle_deaths")      AS "difference_discharge_minus_vehicle"
FROM   combined;