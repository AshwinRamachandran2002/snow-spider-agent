SELECT
    SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc_code",
    COUNT(*) AS "patent_count"
FROM PATENTS.PATENTS.PUBLICATIONS p,
     LATERAL FLATTEN(input => p."ipc") f
WHERE p."country_code" = 'US'
  AND p."kind_code" ILIKE '%B2%'
  AND p."application_kind" = 'A'
  AND p."grant_date" BETWEEN 20220601 AND 20220831
GROUP BY "ipc_code"
ORDER BY "patent_count" DESC NULLS LAST,
         "ipc_code"
LIMIT 1;