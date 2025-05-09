SELECT
  p."publication_number",
  COUNT(*) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS          AS p,
     LATERAL FLATTEN(input => p."citation") AS f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231       -- 2010-01-01 to 2018-12-31
  AND f.value:"category"::STRING ILIKE '%SEA%'           -- keep only SEA-category citations
GROUP BY p."publication_number"
ORDER BY "sea_backward_citation_count" DESC NULLS LAST;