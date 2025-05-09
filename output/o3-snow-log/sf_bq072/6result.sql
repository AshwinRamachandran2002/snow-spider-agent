/* 1)  Identify the race codes whose description contains the word “black”.  */
/* 2)  Restrict DEATHRECORDS to ages 12-18 where age is expressed in years   */
/* 3)  Find every death that has at least one ICD-10 code whose description  */
/*     contains “vehicle” or “firearm” (drawn from ENTITYAXISCONDITIONS).   */
/* 4)  Aggregate by age and by mechanism (Vehicle / Firearm).                */

WITH black_race_codes AS (          -- step-1
    SELECT  "Code"
    FROM    DEATH.DEATH.RACE
    WHERE   LOWER("Description") LIKE '%black%'
),

death_filtered AS (                 -- step-2
    SELECT  D."Id"        AS death_id,
            D."Age",
            D."Race"
    FROM    DEATH.DEATH.DEATHRECORDS D
    WHERE   D."AgeType" = 1                 -- 1 = years
      AND   D."Age" BETWEEN 12 AND 18
),

icd_category AS (                   -- step-3
    SELECT  E."DeathRecordId" AS death_id,
            CASE
                 WHEN I."Description" ILIKE '%vehicle%' THEN 'Vehicle'
                 WHEN I."Description" ILIKE '%firearm%' THEN 'Firearm'
            END                   AS category
    FROM    DEATH.DEATH.ENTITYAXISCONDITIONS  E
    JOIN    DEATH.DEATH.ICD10CODE             I
           ON E."Icd10Code" = I."Code"
    WHERE   I."Description" ILIKE '%vehicle%'
        OR  I."Description" ILIKE '%firearm%'
),

death_with_category AS (            -- combine steps 2 & 3
    SELECT  DISTINCT
            DF."Age",
            IC.category,
            DF.death_id,
            DF."Race"
    FROM    death_filtered DF
    JOIN    icd_category   IC
           ON DF.death_id = IC.death_id
)

/* 4)  Final aggregation                                                    */
SELECT  "Age",
        category,
        COUNT(DISTINCT death_id)                                              AS total_deaths,
        COUNT(DISTINCT CASE WHEN "Race" IN (SELECT "Code" FROM black_race_codes)
                            THEN death_id END)                                AS black_deaths
FROM    death_with_category
GROUP BY "Age", category
ORDER BY "Age" ASC, category ASC;