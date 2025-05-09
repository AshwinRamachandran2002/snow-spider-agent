WITH discharge_codes AS (                  -- ICD‑10 codes whose description contains 'discharge'
    SELECT "Code" AS icd_code
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%discharge%'
      AND LOWER("Description") NOT IN ('urethral discharge',
                                       'discharge of firework')
      AND LOWER("Description") NOT LIKE '%legal intervention involving firearm discharge%'
),
vehicle_codes AS (                         -- ICD‑10 codes whose description contains 'vehicle'
    SELECT "Code" AS icd_code
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%vehicle%'
),

-- keep only white decedents (RaceRecode3 = 1) and tag each record as
-- belonging to the “discharge” or “vehicle” ICD group
death_filtered AS (
    SELECT
        dr."AgeRecode27",
        dr."Icd10Code",
        'discharge'               AS group_type
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN discharge_codes dc
      ON dr."Icd10Code" = dc.icd_code
    WHERE dr."RaceRecode3" = 1

    UNION ALL

    SELECT
        dr."AgeRecode27",
        dr."Icd10Code",
        'vehicle'                 AS group_type
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN vehicle_codes vc
      ON dr."Icd10Code" = vc.icd_code
    WHERE dr."RaceRecode3" = 1
),

-- number of deaths for each ICD‑10 code within every age group
death_counts AS (
    SELECT
        "AgeRecode27",
        group_type,
        "Icd10Code",
        COUNT(*) AS death_count
    FROM death_filtered
    GROUP BY "AgeRecode27", group_type, "Icd10Code"
),

-- average deaths per ICD‑10 code inside each broad ICD group (“discharge” / “vehicle”)
avg_deaths AS (
    SELECT
        "AgeRecode27",
        group_type,
        AVG(death_count) AS avg_deaths
    FROM death_counts
    GROUP BY "AgeRecode27", group_type
),

-- pivot to place both averages on the same row
pivoted AS (
    SELECT
        "AgeRecode27",
        MAX(CASE WHEN group_type = 'discharge' THEN avg_deaths END) AS discharge_avg_deaths,
        MAX(CASE WHEN group_type = 'vehicle'   THEN avg_deaths END) AS vehicle_avg_deaths
    FROM avg_deaths
    GROUP BY "AgeRecode27"
)

-- final result with human‑readable age‑group description and the difference
SELECT
    ar."Description"                                        AS age_group,
    p.discharge_avg_deaths,
    p.vehicle_avg_deaths,
    p.discharge_avg_deaths - p.vehicle_avg_deaths           AS difference_in_avg_deaths
FROM pivoted p
LEFT JOIN DEATH.DEATH.AGERECODE27 ar
       ON p."AgeRecode27" = ar."Code"
ORDER BY p."AgeRecode27";