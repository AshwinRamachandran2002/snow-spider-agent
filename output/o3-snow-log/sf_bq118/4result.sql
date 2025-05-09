/*--------------------------------------------------------------------
  Among white decedents (RaceRecode3 = 1), this query:
  1. Builds two ICD-10 code sets:
        – “discharge”   (descriptions contain “discharge” but NOT the
          three excluded phrases)
        – “vehicle”     (descriptions contain “vehicle”)
  2. Counts deaths per ICD-10 code within each age-group
     (AgeRecode27) for whites.
  3. Computes, for every age-group, the average number of deaths
     across the ICD-10 codes in each set.
  4. Returns the age-group description, the two averages, and the
     difference (discharge − vehicle).
--------------------------------------------------------------------*/
WITH code_categories AS (          -- step-1: build the two ICD-10 sets
    SELECT "Code"              AS icd10,
           'discharge'         AS category
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  UPPER("Description") LIKE '%DISCHARGE%'
      AND  UPPER("Description") NOT LIKE '%URETHRAL DISCHARGE%'
      AND  UPPER("Description") NOT LIKE '%DISCHARGE OF FIREWORK%'
      AND  UPPER("Description") NOT LIKE '%LEGAL INTERVENTION INVOLVING FIREARM DISCHARGE%'

    UNION ALL

    SELECT "Code"              AS icd10,
           'vehicle'           AS category
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  UPPER("Description") LIKE '%VEHICLE%'
),

death_counts AS (                  -- step-2: deaths per code, age-group
    SELECT
        dr."AgeRecode27"      AS age_code,
        cc.category,
        cc.icd10,
        COUNT(*)              AS deaths
    FROM   DEATH.DEATH.DEATHRECORDS dr
    JOIN   code_categories     cc  ON dr."Icd10Code" = cc.icd10
    WHERE  dr."RaceRecode3" = 1            -- white decedents
    GROUP  BY dr."AgeRecode27", cc.category, cc.icd10
),

avg_deaths AS (                    -- step-3: average deaths per category
    SELECT
        age_code,
        category,
        AVG(deaths)            AS avg_deaths
    FROM   death_counts
    GROUP  BY age_code, category
),

pivoted AS (                       -- pivot discharge vs vehicle
    SELECT
        age_code,
        MAX(CASE WHEN category = 'discharge' THEN avg_deaths END) AS avg_discharge,
        MAX(CASE WHEN category = 'vehicle'   THEN avg_deaths END) AS avg_vehicle
    FROM   avg_deaths
    GROUP  BY age_code
)

SELECT
    ar27."Description"                                   AS age_group,
    p.avg_discharge,
    p.avg_vehicle,
    (p.avg_discharge - p.avg_vehicle)                    AS difference
FROM   pivoted                     p
JOIN   DEATH.DEATH.AGERECODE27 ar27 ON p.age_code = ar27."Code"
ORDER  BY p.age_code NULLS LAST;