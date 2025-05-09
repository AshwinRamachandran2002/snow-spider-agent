SELECT
  p."publication_number",
  COUNT(*) AS "sea_backward_citation_cnt"
FROM PATENTS.PATENTS.PUBLICATIONS AS p,
     LATERAL FLATTEN(input => p."citation") AS f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
  AND f.value:"category"::STRING = 'SEA'
GROUP BY p."publication_number"
ORDER BY p."publication_number";