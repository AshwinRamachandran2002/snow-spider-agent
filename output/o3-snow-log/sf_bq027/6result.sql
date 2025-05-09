SELECT
    p."publication_number",
    COUNT(CASE WHEN f.value:"category" = 'SEA' THEN 1 END) AS "sea_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS p,
     LATERAL FLATTEN(input => p."citation", OUTER => TRUE) AS f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
GROUP BY p."publication_number"
ORDER BY "sea_citation_count" DESC NULLS LAST;