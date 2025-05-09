/*  1) Pick WHITE decedents (RaceRecode3 = 'White')
    2) Keep only records whose ICD‑10 description contains
       a) the word “discharge”   (but NOT the three exclusions)  OR
       b) the word “vehicle”
    3) For every AGE‐RECODE‑27 group:
          • count deaths per ICD‑10 code,
          • take the average of those counts (one average for “discharge”, one for “vehicle”)
    4) Return both averages and the difference (discharge – vehicle)
*/
WITH white_deaths AS (          -- all white decedents with ICD‑10 description
    SELECT
        dr."AgeRecode27"               AS age_code,
        icd."Code"                     AS icd_code,
        icd."Description"              AS icd_desc
    FROM DEATH.DEATH.DEATHRECORDS            dr
    JOIN DEATH.DEATH.RACERECODE3             r3
          ON dr."RaceRecode3" = r3."Code"
    JOIN DEATH.DEATH.ICD10CODE               icd
          ON dr."Icd10Code"  = icd."Code"
    WHERE r3."Description" = 'White'
),
tagged AS (                      -- tag each record as discharge / vehicle
    SELECT
        wd.*,
        CASE
            WHEN LOWER(wd.icd_desc) LIKE '%discharge%'
                 AND LOWER(wd.icd_desc) NOT LIKE '%urethral discharge%'
                 AND LOWER(wd.icd_desc) NOT LIKE '%discharge of firework%'
                 AND LOWER(wd.icd_desc) NOT LIKE '%legal intervention involving firearm discharge%'
            THEN 'discharge'
            WHEN LOWER(wd.icd_desc) LIKE '%vehicle%'
            THEN 'vehicle'
        END AS grp
    FROM white_deaths  wd
),
filtered AS (                    -- keep only the tagged rows
    SELECT *
    FROM tagged
    WHERE grp IS NOT NULL
),
death_counts AS (                -- deaths per age‑group & ICD‑10 code
    SELECT
        age_code,
        icd_code,
        grp,
        COUNT(*) AS death_count
    FROM filtered
    GROUP BY age_code, icd_code, grp
),
avg_deaths AS (                  -- average deaths (per ICD‑10) in each age‑group
    SELECT
        age_code,
        grp,
        AVG(death_count) AS avg_death_count
    FROM death_counts
    GROUP BY age_code, grp
)
SELECT
    ad.age_code                                                       AS "AgeRecode27_Code",
    ag27."Description"                                                AS "Age_Group",
    COALESCE(MAX(CASE WHEN ad.grp = 'discharge' THEN ad.avg_death_count END),0)
        AS "Avg_Deaths_Discharge",
    COALESCE(MAX(CASE WHEN ad.grp = 'vehicle'   THEN ad.avg_death_count END),0)
        AS "Avg_Deaths_Vehicle",
    COALESCE(MAX(CASE WHEN ad.grp = 'discharge' THEN ad.avg_death_count END),0)
      - COALESCE(MAX(CASE WHEN ad.grp = 'vehicle'   THEN ad.avg_death_count END),0)
        AS "Difference_Discharge_Minus_Vehicle"
FROM       avg_deaths                        ad
LEFT JOIN  DEATH.DEATH.AGERECODE27           ag27
       ON  ad.age_code = ag27."Code"
GROUP BY ad.age_code, ag27."Description"
ORDER BY ad.age_code;