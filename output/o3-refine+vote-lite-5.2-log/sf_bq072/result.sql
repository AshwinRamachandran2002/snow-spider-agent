WITH
-- list of ages we need to report on
"AGE_LIST" AS (
    SELECT column1::NUMBER AS "Age"
    FROM VALUES (12),(13),(14),(15),(16),(17),(18)
),

/* -----------------------------------------------------------------
   Deaths that have at least one ICD‑10 condition whose description
   contains the word “vehicle”
-------------------------------------------------------------------*/
"VEHICLE_DEATHS" AS (
    SELECT DISTINCT
           D."Id"            AS "DeathId",
           D."Age",
           D."Race"
    FROM DEATH.DEATH.DEATHRECORDS            D
    JOIN DEATH.DEATH.ENTITYAXISCONDITIONS    E  ON D."Id" = E."DeathRecordId"
    JOIN DEATH.DEATH.ICD10CODE               I  ON E."Icd10Code" = I."Code"
    WHERE  UPPER(I."Description") LIKE '%VEHICLE%'
      AND  D."AgeType" = 1                -- age expressed in years
      AND  D."Age" BETWEEN 12 AND 18
),

/* aggregate vehicle‑related deaths */
"VEHICLE_COUNTS" AS (
    SELECT
        V."Age",
        COUNT(*)                                                    AS "total_vehicle",
        SUM(CASE WHEN UPPER(R."Description") LIKE '%BLACK%' THEN 1 ELSE 0 END)  
                                                                  AS "black_vehicle"
    FROM "VEHICLE_DEATHS"              V
    LEFT JOIN DEATH.DEATH.RACE        R  ON V."Race" = R."Code"
    GROUP BY V."Age"
),

/* -----------------------------------------------------------------
   Deaths that have at least one ICD‑10 condition whose description
   contains the word “firearm”
-------------------------------------------------------------------*/
"FIREARM_DEATHS" AS (
    SELECT DISTINCT
           D."Id"            AS "DeathId",
           D."Age",
           D."Race"
    FROM DEATH.DEATH.DEATHRECORDS            D
    JOIN DEATH.DEATH.ENTITYAXISCONDITIONS    E  ON D."Id" = E."DeathRecordId"
    JOIN DEATH.DEATH.ICD10CODE               I  ON E."Icd10Code" = I."Code"
    WHERE  UPPER(I."Description") LIKE '%FIREARM%'
      AND  D."AgeType" = 1                -- age expressed in years
      AND  D."Age" BETWEEN 12 AND 18
),

/* aggregate firearm‑related deaths */
"FIREARM_COUNTS" AS (
    SELECT
        F."Age",
        COUNT(*)                                                    AS "total_firearm",
        SUM(CASE WHEN UPPER(R."Description") LIKE '%BLACK%' THEN 1 ELSE 0 END)  
                                                                  AS "black_firearm"
    FROM "FIREARM_DEATHS"             F
    LEFT JOIN DEATH.DEATH.RACE        R  ON F."Race" = R."Code"
    GROUP BY F."Age"
)

/* -----------------------------------------------------------------
   Final result: one row per age (12‑18) with the requested counts
-------------------------------------------------------------------*/
SELECT
       A."Age",
       COALESCE(V."total_vehicle" , 0) AS "total_vehicle_deaths",
       COALESCE(V."black_vehicle" , 0) AS "black_vehicle_deaths",
       COALESCE(F."total_firearm" , 0) AS "total_firearm_deaths",
       COALESCE(F."black_firearm" , 0) AS "black_firearm_deaths"
FROM "AGE_LIST"          A
LEFT JOIN "VEHICLE_COUNTS" V ON A."Age" = V."Age"
LEFT JOIN "FIREARM_COUNTS" F ON A."Age" = F."Age"
ORDER BY A."Age";