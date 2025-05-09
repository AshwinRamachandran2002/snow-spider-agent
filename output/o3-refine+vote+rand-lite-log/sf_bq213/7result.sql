SELECT 
       ipc4,
       COUNT(*) AS cnt
FROM (
        SELECT 
               SUBSTR(f.value:"code"::string, 1, 4) AS ipc4
        FROM   "PATENTS"."PATENTS"."PUBLICATIONS"  p,
               LATERAL FLATTEN(input => p."ipc") f
        WHERE  p."country_code"     = 'US'
          AND  p."kind_code"        = 'B2'
          AND  p."application_kind" = 'A'
          AND  p."publication_date" BETWEEN 20220601 AND 20220831
) sub
WHERE ipc4 IS NOT NULL
GROUP BY ipc4
ORDER BY cnt DESC NULLS LAST, ipc4
LIMIT 1;