WITH discharge_stats AS (
  SELECT
    COUNT(*) AS total_deaths,
    COUNT(DISTINCT dr."Age") AS total_ages,
    (COUNT(*) / COUNT(DISTINCT dr."Age")) AS average_deaths
  FROM DEATH.DEATH.DEATHRECORDS dr
  JOIN DEATH.DEATH.RACE r ON dr."Race" = r."Code"
  JOIN DEATH.DEATH.ICD10CODE icd ON dr."Icd10Code" = icd."Code"
  WHERE r."Description" = 'White'
    AND icd."Description" ILIKE '%discharge%'
    AND icd."Description" NOT ILIKE '%urethral discharge%'
    AND icd."Description" NOT ILIKE '%firework discharge%'
    AND icd."Description" NOT ILIKE '%legal intervention involving firearm discharge%'
),
vehicle_stats AS (
  SELECT
    COUNT(*) AS total_deaths,
    COUNT(DISTINCT dr."Age") AS total_ages,
    (COUNT(*) / COUNT(DISTINCT dr."Age")) AS average_deaths
  FROM DEATH.DEATH.DEATHRECORDS dr
  JOIN DEATH.DEATH.RACE r ON dr."Race" = r."Code"
  JOIN DEATH.DEATH.ICD10CODE icd ON dr."Icd10Code" = icd."Code"
  WHERE r."Description" = 'White'
    AND icd."Description" ILIKE '%vehicle%'
)
SELECT ROUND((discharge_stats.average_deaths - vehicle_stats.average_deaths), 4) AS "Difference_in_average_deaths"
FROM discharge_stats, vehicle_stats;