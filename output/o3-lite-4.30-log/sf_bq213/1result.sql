SELECT
    SUBSTR(f.value:"code"::STRING, 1, 4) AS ipc_code,
    COUNT(DISTINCT t."publication_number") AS patent_count
FROM PATENTS.PATENTS.PUBLICATIONS t,
     LATERAL FLATTEN(input => t."ipc") f
WHERE t."country_code"     = 'US'
  AND t."kind_code"        = 'B2'
  AND t."application_kind" = 'A'
  AND t."grant_date" BETWEEN 20220601 AND 20220831
GROUP BY ipc_code
ORDER BY patent_count DESC NULLS LAST, ipc_code
LIMIT 1;