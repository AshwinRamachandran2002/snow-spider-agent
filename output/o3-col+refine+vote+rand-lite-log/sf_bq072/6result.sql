WITH dr_filtered AS (   -- deaths of interest: ages 12-18, age type = years
    SELECT
        dr."Id",
        dr."Age",
        dr."RaceRecode5"
    FROM DEATH.DEATH.DEATHRECORDS dr
    WHERE dr."AgeType" = 1
      AND dr."Age" BETWEEN 12 AND 18
),
/* -------------- deaths that include an ICD-10 description containing “vehicle” -------------- */
vehicle_deaths AS (
    SELECT DISTINCT       -- DISTINCT ⇒ each death counted once
        df."Id",
        df."Age"
    FROM dr_filtered           df
    JOIN DEATH.DEATH.ENTITYAXISCONDITIONS eac
        ON df."Id" = eac."DeathRecordId"
    JOIN DEATH.DEATH.ICD10CODE ic
        ON eac."Icd10Code" = ic."Code"
    WHERE ic."Description" ILIKE '%vehicle%'
),
/* -------------- deaths that include an ICD-10 description containing “firearm” -------------- */
firearm_deaths AS (
    SELECT DISTINCT
        df."Id",
        df."Age"
    FROM dr_filtered           df
    JOIN DEATH.DEATH.ENTITYAXISCONDITIONS eac
        ON df."Id" = eac."DeathRecordId"
    JOIN DEATH.DEATH.ICD10CODE ic
        ON eac."Icd10Code" = ic."Code"
    WHERE ic."Description" ILIKE '%firearm%'
),
/* -------------- aggregate stats for “vehicle” deaths -------------- */
vehicle_stats AS (
    SELECT
        vd."Age",
        COUNT(*)                                                              AS vehicle_total_deaths,
        SUM( CASE WHEN rr."Description" ILIKE '%black%' THEN 1 ELSE 0 END )  AS vehicle_black_deaths
    FROM vehicle_deaths                       vd
    JOIN DEATH.DEATH.DEATHRECORDS             dr  ON vd."Id" = dr."Id"
    LEFT JOIN DEATH.DEATH.RACERECODE5         rr  ON dr."RaceRecode5" = rr."Code"
    GROUP BY vd."Age"
),
/* -------------- aggregate stats for “firearm” deaths -------------- */
firearm_stats AS (
    SELECT
        fd."Age",
        COUNT(*)                                                              AS firearm_total_deaths,
        SUM( CASE WHEN rr."Description" ILIKE '%black%' THEN 1 ELSE 0 END )  AS firearm_black_deaths
    FROM firearm_deaths                     fd
    JOIN DEATH.DEATH.DEATHRECORDS           dr  ON fd."Id" = dr."Id"
    LEFT JOIN DEATH.DEATH.RACERECODE5       rr  ON dr."RaceRecode5" = rr."Code"
    GROUP BY fd."Age"
)
/* -------------- combine both sets of results for ages 12-18 -------------- */
SELECT
    ages."Age",
    COALESCE(vs.vehicle_total_deaths , 0) AS "vehicle_total_deaths",
    COALESCE(vs.vehicle_black_deaths , 0) AS "vehicle_black_deaths",
    COALESCE(fs.firearm_total_deaths , 0) AS "firearm_total_deaths",
    COALESCE(fs.firearm_black_deaths , 0) AS "firearm_black_deaths"
FROM (
    SELECT 12 AS "Age" UNION ALL
    SELECT 13 UNION ALL
    SELECT 14 UNION ALL
    SELECT 15 UNION ALL
    SELECT 16 UNION ALL
    SELECT 17 UNION ALL
    SELECT 18
) ages
LEFT JOIN vehicle_stats vs ON ages."Age" = vs."Age"
LEFT JOIN firearm_stats fs ON ages."Age" = fs."Age"
ORDER BY ages."Age";