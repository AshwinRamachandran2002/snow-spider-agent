SELECT t."publication_number",
       COUNT(CASE WHEN c.value:"category"::STRING ILIKE '%SEA%' THEN 1 END) AS "Number_of_Backward_Citations_SEA_Category"
FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
     LATERAL FLATTEN(input => t."citation", OUTER => TRUE) c
WHERE t."grant_date" >= 20100101 AND t."grant_date" <= 20181231
GROUP BY t."publication_number";