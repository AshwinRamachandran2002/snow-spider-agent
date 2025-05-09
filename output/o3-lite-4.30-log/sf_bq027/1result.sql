SELECT
    p."publication_number",
    COUNT_IF(LOWER(f.value:"category"::STRING) LIKE '%sea%') AS backward_citations_sea
FROM PATENTS.PATENTS.PUBLICATIONS AS p,
     LATERAL FLATTEN(input => p."citation", OUTER => TRUE) AS f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
GROUP BY p."publication_number"
ORDER BY p."publication_number";