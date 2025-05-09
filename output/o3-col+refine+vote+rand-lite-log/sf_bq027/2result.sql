SELECT
    p."publication_number",
    COUNT(*) AS "sea_backward_citations"
FROM PATENTS.PATENTS.PUBLICATIONS AS p,
     LATERAL FLATTEN(input => p."citation") AS f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
  AND LOWER(f.value:"category"::STRING) = 'sea'
GROUP BY p."publication_number"
ORDER BY "sea_backward_citations" DESC NULLS LAST;