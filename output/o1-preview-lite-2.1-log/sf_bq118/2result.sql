WITH
discharge_counts AS (
    SELECT "Age", COUNT(*) AS "DeathCount"
    FROM DEATH.DEATH.DEATHRECORDS
    WHERE "Race" = (
        SELECT "Code" FROM DEATH.DEATH.RACE WHERE "Description" = 'White'
    )
    AND "Icd10Code" IN (
        SELECT "Code" FROM DEATH.DEATH.ICD10CODE
        WHERE "Description" ILIKE '%discharge%'
        AND "Description" NOT ILIKE '%urethral discharge%'
        AND "Description" NOT ILIKE '%firework discharge%'
        AND "Description" NOT ILIKE '%legal intervention involving firearm discharge%'
    )
    GROUP BY "Age"
),
vehicle_counts AS (
    SELECT "Age", COUNT(*) AS "DeathCount"
    FROM DEATH.DEATH.DEATHRECORDS
    WHERE "Race" = (
        SELECT "Code" FROM DEATH.DEATH.RACE WHERE "Description" = 'White'
    )
    AND "Icd10Code" IN (
        SELECT "Code" FROM DEATH.DEATH.ICD10CODE
        WHERE "Description" ILIKE '%vehicle%'
    )
    GROUP BY "Age"
),
avg_deaths_discharge AS (
    SELECT AVG("DeathCount") AS avg_deaths_discharge
    FROM discharge_counts
),
avg_deaths_vehicle AS (
    SELECT AVG("DeathCount") AS avg_deaths_vehicle
    FROM vehicle_counts
)
SELECT CAST(ROUND(avg_deaths_discharge.avg_deaths_discharge - avg_deaths_vehicle.avg_deaths_vehicle, 4) AS DECIMAL(10,4)) AS "Difference_in_average_deaths"
FROM avg_deaths_discharge, avg_deaths_vehicle;