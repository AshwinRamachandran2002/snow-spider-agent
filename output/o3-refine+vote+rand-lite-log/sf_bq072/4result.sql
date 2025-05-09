WITH topic_deaths AS (

    /* ------------- VEHICLE–RELATED DEATHS ------------- */
    SELECT  DISTINCT
            dr."Id"              AS death_id,
            dr."Age"             AS age,
            'Vehicle'            AS category,
            dr."Race"            AS race_code
    FROM    DEATH.DEATH.DEATHRECORDS        dr
    JOIN    DEATH.DEATH.ENTITYAXISCONDITIONS eac
           ON dr."Id" = eac."DeathRecordId"
    JOIN    DEATH.DEATH.ICD10CODE            icd
           ON eac."Icd10Code" = icd."Code"
    WHERE   dr."AgeType" = 1                         -- age reported in years
      AND   dr."Age" BETWEEN 12 AND 18
      AND   icd."Description" ILIKE '%vehicle%'

    UNION ALL

    /* ------------- FIREARM–RELATED DEATHS ------------- */
    SELECT  DISTINCT
            dr."Id"              AS death_id,
            dr."Age"             AS age,
            'Firearm'            AS category,
            dr."Race"            AS race_code
    FROM    DEATH.DEATH.DEATHRECORDS        dr
    JOIN    DEATH.DEATH.ENTITYAXISCONDITIONS eac
           ON dr."Id" = eac."DeathRecordId"
    JOIN    DEATH.DEATH.ICD10CODE            icd
           ON eac."Icd10Code" = icd."Code"
    WHERE   dr."AgeType" = 1                         -- age reported in years
      AND   dr."Age" BETWEEN 12 AND 18
      AND   icd."Description" ILIKE '%firearm%'

)

SELECT  td.age                                         AS "Age",
        td.category                                    AS "Category",
        COUNT(DISTINCT td.death_id)                    AS "Total_Deaths",
        SUM(
            CASE 
                 WHEN LOWER(r."Description") LIKE '%black%' 
                 THEN 1 
                 ELSE 0 
            END
        )                                              AS "Black_Deaths"
FROM    topic_deaths        td
LEFT JOIN DEATH.DEATH.RACE  r
       ON td.race_code = r."Code"
GROUP BY td.age, td.category
ORDER BY td.age, td.category;