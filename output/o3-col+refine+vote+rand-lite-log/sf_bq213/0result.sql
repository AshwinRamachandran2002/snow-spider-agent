SELECT 
    SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4",
    COUNT(DISTINCT p."publication_number") AS "patent_count"
FROM PATENTS.PATENTS.PUBLICATIONS p,
     LATERAL FLATTEN(input => p."ipc") f
WHERE p."country_code"    = 'US'
  AND p."kind_code"       = 'B2'          -- granted utility patents
  AND p."application_kind"= 'A'
  AND p."grant_date" BETWEEN 20220601 AND 20220831
GROUP BY "ipc4"
ORDER BY "patent_count" DESC NULLS LAST
LIMIT 1;