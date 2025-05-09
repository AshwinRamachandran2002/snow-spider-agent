SELECT
       t."publication_number",
       COUNT(*) AS "backward_citations_sea"
FROM   PATENTS.PATENTS.PUBLICATIONS t,
       LATERAL FLATTEN(input => t."citation") f
WHERE  t."grant_date" BETWEEN 20100101 AND 20181231
  AND  f.value:"category"::STRING ILIKE 'SEA%'
GROUP BY t."publication_number"
ORDER BY t."publication_number";