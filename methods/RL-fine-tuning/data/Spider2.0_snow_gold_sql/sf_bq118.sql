WITH discharge_codes AS (
  SELECT DISTINCT "Code"
  FROM DEATH.DEATH.ICD10CODE
  WHERE "Description" ILIKE '%discharge%'
    AND "Description" NOT IN ('Urethral discharge', 'Discharge of firework', 'Legal intervention involving firearm discharge')
),
vehicle_codes AS (
  SELECT DISTINCT "Code"
  FROM DEATH.DEATH.ICD10CODE
  WHERE "Description" ILIKE '%vehicle%'
),
discharge_counts AS (
  SELECT
    ar."Description" AS "AgeGroup",
    dr."Icd10Code",
    COUNT(*) AS "DeathCount"
  FROM
    DEATH.DEATH.DEATHRECORDS dr
  JOIN discharge_codes dc ON dr."Icd10Code" = dc."Code"
  JOIN DEATH.DEATH.AGERECODE27 ar ON dr."AgeRecode27" = ar."Code"
  WHERE
    dr."Race" = 1
  GROUP BY
    ar."Description", dr."Icd10Code"
),
vehicle_counts AS (
  SELECT
    ar."Description" AS "AgeGroup",
    dr."Icd10Code",
    COUNT(*) AS "DeathCount"
  FROM
    DEATH.DEATH.DEATHRECORDS dr
  JOIN vehicle_codes vc ON dr."Icd10Code" = vc."Code"
  JOIN DEATH.DEATH.AGERECODE27 ar ON dr."AgeRecode27" = ar."Code"
  WHERE
    dr."Race" = 1
  GROUP BY
    ar."Description", dr."Icd10Code"
),
discharge_avg AS (
  SELECT
    "AgeGroup",
    AVG("DeathCount") AS "AvgDeathsPerCode"
  FROM
    discharge_counts
  GROUP BY
    "AgeGroup"
),
vehicle_avg AS (
  SELECT
    "AgeGroup",
    AVG("DeathCount") AS "AvgDeathsPerCode"
  FROM
    vehicle_counts
  GROUP BY
    "AgeGroup"
),
avg_difference AS (
  SELECT
    d."AgeGroup",
    d."AvgDeathsPerCode" - v."AvgDeathsPerCode" AS "DifferenceInAverageDeathsPerCode"
  FROM
    discharge_avg d
  JOIN vehicle_avg v ON d."AgeGroup" = v."AgeGroup"
)
SELECT
  "AgeGroup",
  ROUND("DifferenceInAverageDeathsPerCode", 4) AS "DifferenceInAverageDeathsPerCode"
FROM
  avg_difference
ORDER BY
  "DifferenceInAverageDeathsPerCode" DESC NULLS LAST;