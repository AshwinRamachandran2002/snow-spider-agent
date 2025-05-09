SELECT
       p."publication_number",
       COUNT(*) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS        AS p,
     LATERAL FLATTEN(input => p."citation") AS c
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
  AND c.value:"category"::STRING ILIKE '%SEA%'
GROUP BY p."publication_number";