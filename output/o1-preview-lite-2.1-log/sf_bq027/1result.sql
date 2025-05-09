SELECT t."publication_number", COUNT(*) AS "Number_of_Backward_Citations_SEA_Category"
FROM PATENTS.PATENTS.PUBLICATIONS t,
     LATERAL FLATTEN(input => t."citation") f
WHERE t."grant_date" BETWEEN 20100101 AND 20181231
  AND f.value:"category"::STRING LIKE '%SEA%'
GROUP BY t."publication_number";