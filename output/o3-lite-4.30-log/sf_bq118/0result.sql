WITH discharge_ct AS (      -- average deaths (per year) whose ICD‑10 description contains “discharge”
    SELECT
        dr."AgeRecode27",
        COUNT(*)::FLOAT / COUNT(DISTINCT dr."CurrentDataYear") AS avg_discharge
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN DEATH.DEATH.ICD10CODE    ic
      ON dr."Icd10Code" = ic."Code"
    WHERE dr."RaceRecode3" = 1                  -- White
      AND ic."Description" ILIKE '%discharge%'
      AND ic."Description" NOT ILIKE '%urethral discharge%'
      AND ic."Description" NOT ILIKE '%discharge of firework%'
      AND ic."Description" NOT ILIKE '%legal intervention involving firearm discharge%'
    GROUP BY dr."AgeRecode27"
),
vehicle_ct AS (            -- average deaths (per year) whose ICD‑10 description contains “vehicle”
    SELECT
        dr."AgeRecode27",
        COUNT(*)::FLOAT / COUNT(DISTINCT dr."CurrentDataYear") AS avg_vehicle
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN DEATH.DEATH.ICD10CODE    ic
      ON dr."Icd10Code" = ic."Code"
    WHERE dr."RaceRecode3" = 1                  -- White
      AND ic."Description" ILIKE '%vehicle%'
    GROUP BY dr."AgeRecode27"
)
SELECT
    ag."Description"                                                         AS age_group,
    ROUND( COALESCE(dc.avg_discharge,0) - COALESCE(vc.avg_vehicle,0) )::INT  AS higher_avg_deaths
FROM DEATH.DEATH.AGERECODE27 ag
LEFT JOIN discharge_ct dc ON ag."Code" = dc."AgeRecode27"
LEFT JOIN vehicle_ct   vc ON ag."Code" = vc."AgeRecode27"
WHERE dc.avg_discharge IS NOT NULL OR vc.avg_vehicle IS NOT NULL
ORDER BY ag."Code";