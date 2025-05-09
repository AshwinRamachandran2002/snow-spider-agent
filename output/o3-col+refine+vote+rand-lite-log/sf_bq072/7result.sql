WITH death_flags AS (
    /*--------------------------------------------------------------------
      For every death record aged 12-18 years,
      flag whether at least one associated ICD-10 code mentions
      ‘vehicle’ and/or ‘firearm’; also flag if the decedent is Black.
    --------------------------------------------------------------------*/
    SELECT
        d."Id"                                   AS "DeathRecordId",
        d."Age",
        /* 1 if ANY ICD-10 description for this death contains ‘vehicle’ */
        MAX( CASE WHEN icd."Description" ILIKE '%vehicle%' THEN 1 ELSE 0 END ) 
            AS "vehicle_flag",
        /* 1 if ANY ICD-10 description for this death contains ‘firearm’ */
        MAX( CASE WHEN icd."Description" ILIKE '%firearm%' THEN 1 ELSE 0 END ) 
            AS "firearm_flag",
        /* 1 if Race-Recode-5 description contains ‘black’, else 0          */
        CASE WHEN rr5."Description" ILIKE '%black%' THEN 1 ELSE 0 END 
            AS "is_black"
    FROM   DEATH.DEATH.DEATHRECORDS          d
    /* race lookup ------------------------------------------------------*/
    LEFT  JOIN DEATH.DEATH.RACERECODE5       rr5
           ON d."RaceRecode5" = rr5."Code"
    /* ICD-10 codes linked through Entity-Axis --------------------------*/
    JOIN   DEATH.DEATH.ENTITYAXISCONDITIONS  e
           ON d."Id" = e."DeathRecordId"
    JOIN   DEATH.DEATH.ICD10CODE             icd
           ON e."Icd10Code" = icd."Code"
    /* only 12-18 year-olds (AgeType = 1 = years) -----------------------*/
    WHERE  d."AgeType" = 1
      AND  d."Age" BETWEEN 12 AND 18
      AND  (
              icd."Description" ILIKE '%vehicle%' 
           OR icd."Description" ILIKE '%firearm%'
          )
    GROUP BY
        d."Id",
        d."Age",
        rr5."Description"
)
/*--------------------------------------------------------------------
  Aggregate the flags to obtain requested counts for every age 12-18.
--------------------------------------------------------------------*/
SELECT
    "Age",
    /* vehicle-related deaths -----------------------------------------*/
    COUNT( DISTINCT CASE WHEN "vehicle_flag" = 1               THEN "DeathRecordId" END ) 
        AS "total_vehicle_deaths",
    COUNT( DISTINCT CASE WHEN "vehicle_flag" = 1 AND "is_black" = 1
                          THEN "DeathRecordId" END ) 
        AS "black_vehicle_deaths",
    /* firearm-related deaths -----------------------------------------*/
    COUNT( DISTINCT CASE WHEN "firearm_flag" = 1               THEN "DeathRecordId" END ) 
        AS "total_firearm_deaths",
    COUNT( DISTINCT CASE WHEN "firearm_flag" = 1 AND "is_black" = 1
                          THEN "DeathRecordId" END ) 
        AS "black_firearm_deaths"
FROM   death_flags
GROUP  BY "Age"
ORDER  BY "Age";