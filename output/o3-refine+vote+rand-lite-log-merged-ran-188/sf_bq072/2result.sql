WITH black_race_codes AS (   -- race codes whose description contains ‘black’
    SELECT "Code"
    FROM DEATH.DEATH.RACE
    WHERE LOWER("Description") LIKE '%black%'
),

/* deaths that involve at least one ICD‑10 code whose description contains
   the word ‘vehicle’ or ‘firearm’ (taken from ENTITYAXISCONDITIONS)          */
death_categories AS (
    SELECT DISTINCT
           E."DeathRecordId",
           CASE
               WHEN LOWER(I."Description") LIKE '%vehicle%'  THEN 'Vehicle'
               WHEN LOWER(I."Description") LIKE '%firearm%' THEN 'Firearm'
           END AS "Category"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS E
    JOIN DEATH.DEATH.ICD10CODE           I  ON E."Icd10Code" = I."Code"
    WHERE LOWER(I."Description") LIKE '%vehicle%'
       OR LOWER(I."Description") LIKE '%firearm%'
),

/* basic information for deaths of persons aged 12‑18                       */
death_info AS (
    SELECT
        DR."Id"   AS "DeathRecordId",
        DR."Age",
        DR."Race"
    FROM DEATH.DEATH.DEATHRECORDS DR
    WHERE DR."Age" BETWEEN 12 AND 18
)

SELECT
    di."Age",
    dc."Category",
    COUNT(*)              AS "Total_Deaths",
    COUNT(brc."Code")     AS "Black_Deaths"
FROM death_info      di
JOIN death_categories dc  ON di."DeathRecordId" = dc."DeathRecordId"
LEFT JOIN black_race_codes brc ON di."Race" = brc."Code"
GROUP BY
    di."Age",
    dc."Category"
ORDER BY
    di."Age",
    dc."Category";