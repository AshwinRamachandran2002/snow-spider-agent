SELECT 
    SUBSTR(f.value:"code"::STRING, 1, 4) AS "IPC4",
    COUNT(DISTINCT p."publication_number") AS "PATENT_COUNT"
FROM PATENTS.PATENTS.PUBLICATIONS p,
     LATERAL FLATTEN(INPUT => p."ipc") f
WHERE p."country_code"     = 'US'
  AND p."kind_code"        = 'B2'
  AND p."application_kind" = 'A'               -- utility patents
  AND p."publication_date" BETWEEN 20220601 AND 20220831  -- June–Aug 2022 grants
  AND f.value:"code" IS NOT NULL
GROUP BY "IPC4"
ORDER BY "PATENT_COUNT" DESC NULLS LAST
LIMIT 1;