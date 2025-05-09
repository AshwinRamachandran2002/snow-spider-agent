WITH
/* 1. Deaths that involved any ICD-10 code whose description contains “vehicle” */
vehicle_deaths AS (
    SELECT DISTINCT e."DeathRecordId"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS e
    JOIN DEATH.DEATH.ICD10CODE           c
          ON e."Icd10Code" = c."Code"
    WHERE LOWER(c."Description") LIKE '%vehicle%'
),

/* 2. Deaths that involved any ICD-10 code whose description contains “firearm” */
firearm_deaths AS (
    SELECT DISTINCT e."DeathRecordId"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS e
    JOIN DEATH.DEATH.ICD10CODE           c
          ON e."Icd10Code" = c."Code"
    WHERE LOWER(c."Description") LIKE '%firearm%'
),

/* 3. Keep only decedents aged 12-18 years (AgeType = 1 ⇒ years) */
deaths_filtered AS (
    SELECT  d."Id"          AS death_id,
            d."Age"         AS age,
            d."Race"        AS race_code,
            r."Description" AS race_desc
    FROM DEATH.DEATH.DEATHRECORDS d
    LEFT JOIN DEATH.DEATH.RACE     r
           ON d."Race" = r."Code"
    WHERE d."AgeType" = 1          -- age reported in years
      AND d."Age" BETWEEN 12 AND 18
),

/* 4. Tag each death with “vehicle”, “firearm”, and “black race” flags */
joined AS (
    SELECT  df.*,
            CASE WHEN vd."DeathRecordId" IS NOT NULL THEN 1 ELSE 0 END AS vehicle_flag,
            CASE WHEN fd."DeathRecordId" IS NOT NULL THEN 1 ELSE 0 END AS firearm_flag,
            CASE WHEN LOWER(df.race_desc) LIKE '%black%' THEN 1 ELSE 0 END AS black_flag
    FROM deaths_filtered df
    LEFT JOIN vehicle_deaths vd
           ON df.death_id = vd."DeathRecordId"
    LEFT JOIN firearm_deaths fd
           ON df.death_id = fd."DeathRecordId"
)

/* 5. Aggregate the requested counts for each age 12-18 */
SELECT
    age,
    COUNT(DISTINCT IFF(vehicle_flag = 1, death_id, NULL))                           AS vehicle_total_deaths,
    COUNT(DISTINCT IFF(vehicle_flag = 1 AND black_flag = 1, death_id, NULL))        AS vehicle_black_deaths,
    COUNT(DISTINCT IFF(firearm_flag = 1, death_id, NULL))                           AS firearm_total_deaths,
    COUNT(DISTINCT IFF(firearm_flag = 1 AND black_flag = 1, death_id, NULL))        AS firearm_black_deaths
FROM joined
GROUP BY age
ORDER BY age;