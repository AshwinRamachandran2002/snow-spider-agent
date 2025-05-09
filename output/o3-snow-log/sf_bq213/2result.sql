SELECT 
       SUBSTR(TO_VARCHAR(ipc_item.value:"code"), 1, 4) AS "IPC4",
       COUNT(*) AS "CNT"
FROM   PATENTS.PATENTS.PUBLICATIONS AS p,
       LATERAL FLATTEN(input => p."ipc") AS ipc_item
WHERE  p."country_code"     = 'US'
  AND  p."kind_code"        = 'B2'           -- granted US utility patents
  AND  p."application_kind" = 'A'            -- utility patents
  AND  p."grant_date" BETWEEN 20220601 AND 20220831   -- June–August 2022
  AND  ipc_item.value:"code" IS NOT NULL
GROUP BY "IPC4"
ORDER BY "CNT" DESC NULLS LAST
LIMIT 1;