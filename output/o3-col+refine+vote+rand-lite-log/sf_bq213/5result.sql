SELECT  
    SUBSTR(f.value:"code"::STRING, 1, 4)      AS "ipc4",
    COUNT(*)                                   AS "occurrences"
FROM  PATENTS.PATENTS.PUBLICATIONS t,
      LATERAL FLATTEN(INPUT => t."ipc") f
WHERE t."country_code"      = 'US'
  AND t."kind_code"         = 'B2'
  AND t."application_kind"  = 'A'
  AND t."grant_date" BETWEEN 20220601 AND 20220831
GROUP BY SUBSTR(f.value:"code"::STRING, 1, 4)
ORDER BY "occurrences" DESC NULLS LAST
LIMIT 1;