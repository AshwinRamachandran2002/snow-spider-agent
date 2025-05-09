/*  Vehicle- and Firearm-related deaths, ages 12-18  */
WITH "cause_codes" AS (      -- ICD-10 codes whose descriptions mention “vehicle” or “firearm”
    SELECT "Code" AS icd10_code,
           'vehicle'  AS cause_type
    FROM   DEATH.DEATH."ICD10CODE"
    WHERE  UPPER("Description") LIKE '%VEHICLE%'

    UNION ALL

    SELECT "Code" AS icd10_code,
           'firearm' AS cause_type
    FROM   DEATH.DEATH."ICD10CODE"
    WHERE  UPPER("Description") LIKE '%FIREARM%'
),
"deaths_with_cause" AS (     -- each death record that contains at least one such code
    SELECT DISTINCT
           e."DeathRecordId"  AS death_id,
           c.cause_type
    FROM   DEATH.DEATH."ENTITYAXISCONDITIONS" e
    JOIN   "cause_codes"      c
           ON e."Icd10Code" = c.icd10_code
),
"race_lookup" AS (           -- race descriptions
    SELECT "Code",
           "Description"
    FROM   DEATH.DEATH."RACE"
)
SELECT
       dr."Age"                                           AS age,
       dc.cause_type,
       COUNT(*)                                           AS total_deaths,
       COUNT(CASE WHEN UPPER(rl."Description") LIKE '%BLACK%' THEN 1 END) AS black_deaths
FROM   "deaths_with_cause"   dc
JOIN   DEATH.DEATH."DEATHRECORDS" dr
       ON dr."Id" = dc.death_id
LEFT  JOIN "race_lookup"     rl
       ON rl."Code" = dr."Race"
WHERE  dr."Age" BETWEEN 12 AND 18          -- ages 12-18, inclusive
  AND  dr."AgeType" = 1                    -- Age reported in years
GROUP BY
       dr."Age",
       dc.cause_type
ORDER BY
       dr."Age",
       dc.cause_type;