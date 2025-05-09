SELECT
    p."publication_number"                       AS publication_number,
    COUNT(*)                                     AS backward_citations_sea
FROM PATENTS.PATENTS.PUBLICATIONS p,
     LATERAL FLATTEN(input => p."citation") f
WHERE p."grant_date" BETWEEN 20100101 AND 20181231
  AND f.value:"category"::STRING ILIKE '%SEA%'
GROUP BY p."publication_number"
ORDER BY p."publication_number";