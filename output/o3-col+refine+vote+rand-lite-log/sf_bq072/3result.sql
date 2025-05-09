WITH race_black AS (          -- codes whose race description contains “black”
    SELECT "Code" AS race_code
    FROM   DEATH.DEATH.RACE
    WHERE  "Description" ILIKE '%black%'
),
death_flags AS (              -- one row per death, with flags for vehicle / firearm involvement
    SELECT
        d."Id"  AS death_id,
        d."Age",
        d."Race",
        MAX(CASE WHEN icd."Description" ILIKE '%vehicle%' THEN 1 ELSE 0 END)  AS vehicle_flag,
        MAX(CASE WHEN icd."Description" ILIKE '%firearm%' THEN 1 ELSE 0 END)  AS firearm_flag
    FROM   DEATH.DEATH.DEATHRECORDS         d
    JOIN   DEATH.DEATH.ENTITYAXISCONDITIONS e   ON e."DeathRecordId" = d."Id"
    JOIN   DEATH.DEATH.ICD10CODE            icd ON icd."Code"        = e."Icd10Code"
    WHERE  d."Age" BETWEEN 12 AND 18               -- ages 12-18, inclusive
      AND  d."AgeType" = 1                         -- 1 = Years (per AGETYPE table)
    GROUP BY d."Id", d."Age", d."Race"
)
SELECT
    df."Age",
    /* vehicle-related deaths */
    SUM(CASE WHEN df.vehicle_flag = 1                               THEN 1 ELSE 0 END) AS vehicle_total,
    SUM(CASE WHEN df.vehicle_flag = 1 AND rb.race_code IS NOT NULL  THEN 1 ELSE 0 END) AS vehicle_black,
    /* firearm-related deaths */
    SUM(CASE WHEN df.firearm_flag = 1                               THEN 1 ELSE 0 END) AS firearm_total,
    SUM(CASE WHEN df.firearm_flag = 1 AND rb.race_code IS NOT NULL  THEN 1 ELSE 0 END) AS firearm_black
FROM   death_flags df
LEFT  JOIN race_black rb
       ON rb.race_code = df."Race"
GROUP BY df."Age"
ORDER BY df."Age";