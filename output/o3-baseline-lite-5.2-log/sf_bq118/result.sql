WITH discharge_codes AS (       -- ICD‑10 codes that mention “discharge”, minus the three exclusions
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%discharge%'
      AND LOWER("Description") NOT LIKE '%urethral discharge%'
      AND LOWER("Description") NOT LIKE '%discharge of firework%'
      AND LOWER("Description") NOT LIKE '%legal intervention involving firearm discharge%'
),
vehicle_codes AS (              -- ICD‑10 codes that mention “vehicle”
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%vehicle%'
),

/*---------------------------------------------------------*
 |  Death counts (white only) by age‑group × ICD‑10 code   |
 *---------------------------------------------------------*/
discharge_deaths AS (
    SELECT
        dr."AgeRecode27"  AS "AgeGroupCode",
        dr."Icd10Code"    AS "Icd10Code",
        COUNT(*)          AS "Deaths"
    FROM DEATH.DEATH.DEATHRECORDS dr
    WHERE dr."RaceRecode3" = 1                       -- White
      AND dr."Icd10Code" IN (SELECT "Code" FROM discharge_codes)
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),
vehicle_deaths AS (
    SELECT
        dr."AgeRecode27"  AS "AgeGroupCode",
        dr."Icd10Code"    AS "Icd10Code",
        COUNT(*)          AS "Deaths"
    FROM DEATH.DEATH.DEATHRECORDS dr
    WHERE dr."RaceRecode3" = 1                       -- White
      AND dr."Icd10Code" IN (SELECT "Code" FROM vehicle_codes)
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),

/*---------------------------------------------------------*
 |  Average deaths per ICD‑10 code within each age group   |
 *---------------------------------------------------------*/
avg_discharge AS (
    SELECT
        "AgeGroupCode",
        AVG("Deaths") AS "AvgDischargeDeaths"
    FROM discharge_deaths
    GROUP BY "AgeGroupCode"
),
avg_vehicle AS (
    SELECT
        "AgeGroupCode",
        AVG("Deaths") AS "AvgVehicleDeaths"
    FROM vehicle_deaths
    GROUP BY "AgeGroupCode"
)

/*---------------------------------------------------------*
 |  Final output: difference in averages by age group      |
 *---------------------------------------------------------*/
SELECT
    COALESCE(ad."AgeGroupCode", av."AgeGroupCode")                            AS "AgeRecode27",
    ag27."Description"                                                       AS "AgeGroupDescription",
    COALESCE(ad."AvgDischargeDeaths", 0)                                      AS "AvgDischargeDeaths",
    COALESCE(av."AvgVehicleDeaths",   0)                                      AS "AvgVehicleDeaths",
    COALESCE(ad."AvgDischargeDeaths", 0) 
      - COALESCE(av."AvgVehicleDeaths", 0)                                    AS "Difference"
FROM avg_discharge ad
FULL JOIN avg_vehicle av
       ON ad."AgeGroupCode" = av."AgeGroupCode"
LEFT JOIN DEATH.DEATH.AGERECODE27 ag27
       ON ag27."Code" = COALESCE(ad."AgeGroupCode", av."AgeGroupCode")
ORDER BY "AgeRecode27";