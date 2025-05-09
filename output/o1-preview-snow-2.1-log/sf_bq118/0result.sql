SELECT
     ROUND(discharge_avg."Average_Deaths" - vehicle_avg."Average_Deaths", 4) AS "Difference_in_average_deaths"
FROM
     (SELECT AVG(sub."Death_Count") AS "Average_Deaths"
      FROM (
        SELECT dr."Age", COUNT(*) AS "Death_Count"
        FROM "DEATH"."DEATH"."DEATHRECORDS" dr
        JOIN "DEATH"."DEATH"."ICD10CODE" ic ON dr."Icd10Code" = ic."Code"
        WHERE dr."Race" = 1
          AND ic."Description" ILIKE '%discharge%'
          AND ic."Description" NOT ILIKE '%urethral%'
          AND ic."Description" NOT ILIKE '%firework%'
          AND ic."Description" NOT ILIKE '%legal intervention involving firearm%'
        GROUP BY dr."Age"
      ) sub
     ) discharge_avg,
     (SELECT AVG(sub."Death_Count") AS "Average_Deaths"
      FROM (
        SELECT dr."Age", COUNT(*) AS "Death_Count"
        FROM "DEATH"."DEATH"."DEATHRECORDS" dr
        JOIN "DEATH"."DEATH"."ICD10CODE" ic ON dr."Icd10Code" = ic."Code"
        WHERE dr."Race" = 1
          AND ic."Description" ILIKE '%vehicle%'
        GROUP BY dr."Age"
      ) sub
     ) vehicle_avg;