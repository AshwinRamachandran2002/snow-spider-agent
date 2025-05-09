SELECT 
    SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4",
    COUNT(*) AS "occurrences"
FROM PATENTS.PATENTS.PUBLICATIONS p,
     LATERAL FLATTEN(INPUT => p."ipc") f
WHERE p."country_code"      = 'US'
  AND p."kind_code"         = 'B2'
  AND p."application_kind"  = 'A'      -- utility patents
  AND p."grant_date" BETWEEN 20220601 AND 20220831
GROUP BY "ipc4"
ORDER BY "occurrences" DESC NULLS LAST
LIMIT 1;