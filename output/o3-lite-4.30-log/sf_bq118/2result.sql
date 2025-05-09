WITH discharge_deaths AS (
    SELECT
        dr."AgeRecode27" AS age_code,
        COUNT(*)         AS discharge_cnt
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN DEATH.DEATH.ICD10CODE icd
      ON dr."Icd10Code" = icd."Code"
    WHERE dr."RaceRecode3" = 1
      AND icd."Description" ILIKE '%discharge%'
      AND icd."Description" NOT ILIKE '%urethral%discharge%'
      AND icd."Description" NOT ILIKE '%firework%'
      AND icd."Description" NOT ILIKE '%firearm%discharge%'
    GROUP BY dr."AgeRecode27"
), 
vehicle_deaths AS (
    SELECT
        dr."AgeRecode27" AS age_code,
        COUNT(*)         AS vehicle_cnt
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN DEATH.DEATH.ICD10CODE icd
      ON dr."Icd10Code" = icd."Code"
    WHERE dr."RaceRecode3" = 1
      AND icd."Description" ILIKE '%vehicle%'
    GROUP BY dr."AgeRecode27"
)
SELECT
    ar."Description"                                          AS age_group,
    COALESCE(d.discharge_cnt, 0) - COALESCE(v.vehicle_cnt, 0) AS higher_avg_deaths
FROM DEATH.DEATH.AGERECODE27 ar
LEFT JOIN discharge_deaths d ON ar."Code" = d.age_code
LEFT JOIN vehicle_deaths   v ON ar."Code" = v.age_code
ORDER BY ar."Code";