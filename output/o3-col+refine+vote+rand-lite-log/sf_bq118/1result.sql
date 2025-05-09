WITH discharge AS (   -- average deaths per ICD-10 code that mention “discharge” (with exclusions)
    SELECT
        sub."AgeRecode12",
        AVG(sub.death_cnt) AS avg_deaths_discharge
    FROM (
        SELECT
            dr."AgeRecode12",
            dr."Icd10Code",
            COUNT(*) AS death_cnt
        FROM   DEATH.DEATH.DEATHRECORDS  dr
        JOIN   DEATH.DEATH.ICD10CODE     icd
               ON dr."Icd10Code" = icd."Code"
        WHERE  dr."RaceRecode3" = 1                       -- White decedents
          AND  icd."Description" ILIKE '%discharge%'
          AND  icd."Description" NOT ILIKE '%urethral discharge%'
          AND  icd."Description" NOT ILIKE '%discharge of firework%'
          AND  icd."Description" NOT ILIKE '%legal intervention involving firearm discharge%'
        GROUP BY dr."AgeRecode12", dr."Icd10Code"
    ) sub
    GROUP BY sub."AgeRecode12"
), vehicle AS (        -- average deaths per ICD-10 code that mention “vehicle”
    SELECT
        sub."AgeRecode12",
        AVG(sub.death_cnt) AS avg_deaths_vehicle
    FROM (
        SELECT
            dr."AgeRecode12",
            dr."Icd10Code",
            COUNT(*) AS death_cnt
        FROM   DEATH.DEATH.DEATHRECORDS  dr
        JOIN   DEATH.DEATH.ICD10CODE     icd
               ON dr."Icd10Code" = icd."Code"
        WHERE  dr."RaceRecode3" = 1                       -- White decedents
          AND  icd."Description" ILIKE '%vehicle%'
        GROUP BY dr."AgeRecode12", dr."Icd10Code"
    ) sub
    GROUP BY sub."AgeRecode12"
)
SELECT
    ag."Code"                                       AS "AgeGrpCode",
    ag."Description"                                AS "AgeGrpDesc",
    d.avg_deaths_discharge,
    v.avg_deaths_vehicle,
    (d.avg_deaths_discharge - v.avg_deaths_vehicle) AS "AvgDifference"
FROM       discharge d
JOIN       vehicle   v   ON d."AgeRecode12" = v."AgeRecode12"
JOIN       DEATH.DEATH.AGERECODE12 ag
           ON ag."Code" = d."AgeRecode12"
ORDER BY   ag."Code";