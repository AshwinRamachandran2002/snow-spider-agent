WITH
WhiteRaceCode AS (
    SELECT "Code" AS "WhiteCode"
    FROM "DEATH"."DEATH"."RACE"
    WHERE "Description" = 'White'
),
DischargeICD10Codes AS (
    SELECT "Code" AS "Icd10Code"
    FROM "DEATH"."DEATH"."ICD10CODE"
    WHERE "Description" ILIKE '%discharge%'
      AND "Description" NOT ILIKE '%Urethral discharge%'
      AND "Description" NOT ILIKE '%Discharge of firework%'
      AND "Description" NOT ILIKE '%Legal intervention involving firearm discharge%'
),
VehicleICD10Codes AS (
    SELECT "Code" AS "Icd10Code"
    FROM "DEATH"."DEATH"."ICD10CODE"
    WHERE "Description" ILIKE '%vehicle%'
),
DischargeCounts AS (
    SELECT DR."AgeRecode12", DR."Icd10Code", COUNT(*) AS "DeathCount"
    FROM "DEATH"."DEATH"."DEATHRECORDS" AS DR
    WHERE DR."Race" = (SELECT "WhiteCode" FROM WhiteRaceCode)
      AND DR."Icd10Code" IN (SELECT "Icd10Code" FROM DischargeICD10Codes)
    GROUP BY DR."AgeRecode12", DR."Icd10Code"
),
DischargeAvgDeaths AS (
    SELECT "AgeRecode12", AVG("DeathCount") AS "DischargeAvgDeathPerCode"
    FROM DischargeCounts
    GROUP BY "AgeRecode12"
),
VehicleCounts AS (
    SELECT DR."AgeRecode12", DR."Icd10Code", COUNT(*) AS "DeathCount"
    FROM "DEATH"."DEATH"."DEATHRECORDS" AS DR
    WHERE DR."Race" = (SELECT "WhiteCode" FROM WhiteRaceCode)
      AND DR."Icd10Code" IN (SELECT "Icd10Code" FROM VehicleICD10Codes)
    GROUP BY DR."AgeRecode12", DR."Icd10Code"
),
VehicleAvgDeaths AS (
    SELECT "AgeRecode12", AVG("DeathCount") AS "VehicleAvgDeathPerCode"
    FROM VehicleCounts
    GROUP BY "AgeRecode12"
),
DeathAvgDifference AS (
    SELECT
        COALESCE(DAD."AgeRecode12", VAD."AgeRecode12") AS "AgeRecode12",
        DAD."DischargeAvgDeathPerCode",
        VAD."VehicleAvgDeathPerCode",
        ROUND(
            CASE
                WHEN (DAD."DischargeAvgDeathPerCode" - VAD."VehicleAvgDeathPerCode") > 0
                THEN (DAD."DischargeAvgDeathPerCode" - VAD."VehicleAvgDeathPerCode")
                ELSE 0
            END,
            4
        ) AS "DifferenceInAverageDeathsPerCode"
    FROM DischargeAvgDeaths DAD
    FULL OUTER JOIN VehicleAvgDeaths VAD
    ON DAD."AgeRecode12" = VAD."AgeRecode12"
),
AgeGroups AS (
    SELECT "Code", "Description" AS "AgeGroup"
    FROM "DEATH"."DEATH"."AGERECODE12"
)
SELECT
    AG."AgeGroup",
    DAD."DifferenceInAverageDeathsPerCode"
FROM DeathAvgDifference DAD
JOIN AgeGroups AG
ON DAD."AgeRecode12" = AG."Code"
ORDER BY CAST(AG."Code" AS INTEGER);