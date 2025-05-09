/*  STEP-BY-STEP
    1. Keep only White decedents (RaceRecode3 = 1).
    2. Join to ICD10CODE to obtain the textual description of every code.
    3. Tag each record as “discharge” or “vehicle”.
       – “discharge”  : description contains the word discharge
                        but NOT the three excluded phrases.
       – “vehicle”    : description contains the word vehicle.
    4. For every age-group (AgeRecode27) and category, count deaths
       for EACH individual ICD-10 code, then take the average of those
       counts across the different codes (“average number of deaths
       per ICD-10 code” within that age group & category).
    5. Pivot the two categories side-by-side and compute the difference
       (discharge – vehicle).
    6. Attach the human-readable age-group description.
*/
WITH white_records AS (   -- all WHITE deaths with an ICD10 code & age group
    SELECT
        d."AgeRecode27",
        d."Icd10Code"
    FROM DEATH.DEATH.DEATHRECORDS d
    WHERE d."RaceRecode3" = 1              -- White
      AND d."AgeRecode27" IS NOT NULL
      AND d."Icd10Code"   IS NOT NULL
),
joined AS (               -- add ICD-10 description
    SELECT
        w."AgeRecode27",
        w."Icd10Code",
        i."Description"
    FROM white_records w
    JOIN DEATH.DEATH.ICD10CODE i
      ON i."Code" = w."Icd10Code"
),
categorized AS (          -- keep only rows that fit either category
    SELECT
        j."AgeRecode27",
        j."Icd10Code",
        CASE
            WHEN j."Description" ILIKE '%discharge%'
                 AND j."Description" NOT ILIKE '%urethral discharge%'
                 AND j."Description" NOT ILIKE '%discharge of firework%'
                 AND j."Description" NOT ILIKE '%legal intervention involving firearm discharge%'
                 THEN 'discharge'
            WHEN j."Description" ILIKE '%vehicle%' THEN 'vehicle'
        END AS category
    FROM joined j
    WHERE ( j."Description" ILIKE '%discharge%'
               AND j."Description" NOT ILIKE '%urethral discharge%'
               AND j."Description" NOT ILIKE '%discharge of firework%'
               AND j."Description" NOT ILIKE '%legal intervention involving firearm discharge%' )
       OR j."Description" ILIKE '%vehicle%'
),
deaths_per_code AS (      -- deaths per ICD-10 code, age group & category
    SELECT
        c."AgeRecode27",
        c.category,
        c."Icd10Code",
        COUNT(*) AS death_count
    FROM categorized c
    GROUP BY c."AgeRecode27", c.category, c."Icd10Code"
),
avg_deaths AS (           -- average # deaths per ICD-10 code within group
    SELECT
        "AgeRecode27",
        category,
        AVG(death_count) AS avg_deaths
    FROM deaths_per_code
    GROUP BY "AgeRecode27", category
),
pivoted AS (              -- place discharge & vehicle side-by-side
    SELECT
        a."AgeRecode27",
        MAX(CASE WHEN a.category = 'discharge' THEN a.avg_deaths END) AS avg_discharge,
        MAX(CASE WHEN a.category = 'vehicle'   THEN a.avg_deaths END) AS avg_vehicle
    FROM avg_deaths a
    GROUP BY a."AgeRecode27"
)
SELECT
    ag27."Description"                            AS age_group,
    p.avg_discharge,
    p.avg_vehicle,
    (p.avg_discharge - p.avg_vehicle)             AS diff_avg_deaths
FROM pivoted p
LEFT JOIN DEATH.DEATH.AGERECODE27 ag27
       ON ag27."Code" = p."AgeRecode27"
ORDER BY ag27."Code";