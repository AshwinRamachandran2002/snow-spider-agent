SELECT
    SUBSTR(f.value:"code"::STRING, 1, 4) AS "most_common_ipc4",
    COUNT(*)                                   AS "frequency"
FROM PATENTS.PATENTS.PUBLICATIONS p,
     LATERAL FLATTEN(input => p."ipc") f
WHERE p."country_code"     = 'US'
  AND p."kind_code"        = 'B2'
  AND p."application_kind" = 'A'
  AND p."grant_date" BETWEEN 20220601 AND 20220831
GROUP BY "most_common_ipc4"
ORDER BY "frequency" DESC NULLS LAST
LIMIT 1;