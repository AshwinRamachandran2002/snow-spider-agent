WITH discharge_codes AS
(
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%discharge%'
      AND "Description" NOT ILIKE 'Urethral discharge'
      AND "Description" NOT ILIKE 'Discharge of firework'
      AND "Description" NOT ILIKE 'Legal intervention involving firearm discharge'
),
vehicle_codes AS
(
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%vehicle%'
),
-- deaths per ICD-10 code per age group (discharge)
deaths_discharge AS
(
    SELECT
        DR."AgeRecode27"            AS age_code,
        DR."Icd10Code",
        COUNT(*)                    AS death_count
    FROM DEATH.DEATH.DEATHRECORDS DR
    WHERE DR."Race" = 1                                -- White
      AND DR."Icd10Code" IN (SELECT "Code" FROM discharge_codes)
    GROUP BY DR."AgeRecode27", DR."Icd10Code"
),
avg_discharge AS
(
    SELECT
        age_code,
        AVG(death_count) AS avg_deaths_discharge
    FROM deaths_discharge
    GROUP BY age_code
),
-- deaths per ICD-10 code per age group (vehicle)
deaths_vehicle AS
(
    SELECT
        DR."AgeRecode27"            AS age_code,
        DR."Icd10Code",
        COUNT(*)                    AS death_count
    FROM DEATH.DEATH.DEATHRECORDS DR
    WHERE DR."Race" = 1                                -- White
      AND DR."Icd10Code" IN (SELECT "Code" FROM vehicle_codes)
    GROUP BY DR."AgeRecode27", DR."Icd10Code"
),
avg_vehicle AS
(
    SELECT
        age_code,
        AVG(death_count) AS avg_deaths_vehicle
    FROM deaths_vehicle
    GROUP BY age_code
)
SELECT
    AR."Description"                                                         AS age_group,
    COALESCE(AD.avg_deaths_discharge, 0)                                     AS avg_deaths_discharge,
    COALESCE(AV.avg_deaths_vehicle,   0)                                     AS avg_deaths_vehicle,
    COALESCE(AD.avg_deaths_discharge, 0) - COALESCE(AV.avg_deaths_vehicle,0) AS difference_discharge_minus_vehicle
FROM DEATH.DEATH.AGERECODE27 AR
LEFT JOIN avg_discharge AD ON AD.age_code = AR."Code"
LEFT JOIN avg_vehicle   AV ON AV.age_code = AR."Code"
ORDER BY AR."Code" NULLS LAST;