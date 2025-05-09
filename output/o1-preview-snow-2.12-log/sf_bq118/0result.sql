WITH DischargeCodes AS (
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE "Description" ILIKE '%discharge%'
      AND "Description" NOT ILIKE '%Urethral discharge%'
      AND "Description" NOT ILIKE '%Discharge of firework%'
      AND "Description" NOT ILIKE '%Legal intervention involving firearm discharge%'
),
VehicleCodes AS (
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE "Description" ILIKE '%vehicle%'
),
WhiteRaceCode AS (
    SELECT "Code"
    FROM DEATH.DEATH.RACE
    WHERE "Description" = 'White'
),
AgeGroups AS (
    SELECT "Code" AS "AgeRecode27", "Description" AS "AgeGroup"
    FROM DEATH.DEATH.AGERECODE27
),
DischargeCounts AS (
    SELECT
        dr."AgeRecode27",
        dr."Icd10Code",
        COUNT(*) AS "DeathCount"
    FROM DEATH.DEATH.DEATHRECORDS dr
    WHERE dr."Icd10Code" IN (SELECT "Code" FROM DischargeCodes)
      AND dr."Race" = (SELECT "Code" FROM WhiteRaceCode)
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),
VehicleCounts AS (
    SELECT
        dr."AgeRecode27",
        dr."Icd10Code",
        COUNT(*) AS "DeathCount"
    FROM DEATH.DEATH.DEATHRECORDS dr
    WHERE dr."Icd10Code" IN (SELECT "Code" FROM VehicleCodes)
      AND dr."Race" = (SELECT "Code" FROM WhiteRaceCode)
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),
AvgDischargeByAge AS (
    SELECT
        dc."AgeRecode27",
        AVG(dc."DeathCount") AS "AvgDischargeDeathsPerCode"
    FROM DischargeCounts dc
    GROUP BY dc."AgeRecode27"
),
AvgVehicleByAge AS (
    SELECT
        vc."AgeRecode27",
        AVG(vc."DeathCount") AS "AvgVehicleDeathsPerCode"
    FROM VehicleCounts vc
    GROUP BY vc."AgeRecode27"
),
DifferenceByAge AS (
    SELECT
        ag."AgeGroup",
        ROUND(COALESCE(ad."AvgDischargeDeathsPerCode", 0) - COALESCE(av."AvgVehicleDeathsPerCode", 0), 4) AS "DifferenceInAverageDeathsPerCode"
    FROM AgeGroups ag
    LEFT JOIN AvgDischargeByAge ad ON ag."AgeRecode27" = ad."AgeRecode27"
    LEFT JOIN AvgVehicleByAge av ON ag."AgeRecode27" = av."AgeRecode27"
)
SELECT
    "AgeGroup",
    "DifferenceInAverageDeathsPerCode"
FROM DifferenceByAge
WHERE "DifferenceInAverageDeathsPerCode" > 0
ORDER BY "AgeGroup";