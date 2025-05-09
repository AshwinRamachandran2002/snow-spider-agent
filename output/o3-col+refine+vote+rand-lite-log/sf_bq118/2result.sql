WITH discharge AS (
    SELECT
        ag."Description"                                       AS "Age_Group",
        AVG(sub.death_cnt)                                     AS "avg_discharge_per_code"
    FROM (
        SELECT
            dr."AgeRecode27",
            dr."Icd10Code",
            COUNT(*)                                           AS death_cnt
        FROM DEATH.DEATH.DEATHRECORDS           dr
        JOIN DEATH.DEATH.ICD10CODE               ic
              ON dr."Icd10Code" = ic."Code"
        WHERE ic."Description" ILIKE '%discharge%'
          AND ic."Description" NOT ILIKE '%Urethral discharge%'
          AND ic."Description" NOT ILIKE '%Discharge of firework%'
          AND ic."Description" NOT ILIKE '%Legal intervention involving firearm discharge%'
          AND dr."RaceRecode3" = 1      -- White decedents
        GROUP BY dr."AgeRecode27", dr."Icd10Code"
    ) sub
    JOIN DEATH.DEATH.AGERECODE27               ag
          ON sub."AgeRecode27" = ag."Code"
    GROUP BY ag."Description"
),
vehicle AS (
    SELECT
        ag."Description"                                       AS "Age_Group",
        AVG(sub.death_cnt)                                     AS "avg_vehicle_per_code"
    FROM (
        SELECT
            dr."AgeRecode27",
            dr."Icd10Code",
            COUNT(*)                                           AS death_cnt
        FROM DEATH.DEATH.DEATHRECORDS           dr
        JOIN DEATH.DEATH.ICD10CODE               ic
              ON dr."Icd10Code" = ic."Code"
        WHERE ic."Description" ILIKE '%vehicle%'
          AND dr."RaceRecode3" = 1      -- White decedents
        GROUP BY dr."AgeRecode27", dr."Icd10Code"
    ) sub
    JOIN DEATH.DEATH.AGERECODE27               ag
          ON sub."AgeRecode27" = ag."Code"
    GROUP BY ag."Description"
)
SELECT
    COALESCE(d."Age_Group", v."Age_Group")                     AS "Age_Group",
    d."avg_discharge_per_code",
    v."avg_vehicle_per_code",
    (d."avg_discharge_per_code" - v."avg_vehicle_per_code")    AS "difference_discharge_minus_vehicle"
FROM discharge d
FULL JOIN vehicle v
       ON d."Age_Group" = v."Age_Group"
ORDER BY "difference_discharge_minus_vehicle" DESC NULLS LAST;