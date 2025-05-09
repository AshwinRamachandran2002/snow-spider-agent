/* Most common 4-digit IPC code among U.S. B2 utility patents granted Jun–Aug 2022 */
SELECT 
    SUBSTR(ip.value:"code"::STRING, 1, 4) AS "ipc4",
    COUNT(*)                               AS "cnt"
FROM PATENTS.PATENTS.PUBLICATIONS p,
     LATERAL FLATTEN(input => p."ipc") ip
WHERE p."country_code"      = 'US'
  AND p."kind_code"         = 'B2'      -- patent grants
  AND p."application_kind"  = 'A'       -- utility patents
  AND p."grant_date" BETWEEN 20220601 AND 20220831
GROUP BY "ipc4"
ORDER BY "cnt" DESC NULLS LAST
LIMIT 1;