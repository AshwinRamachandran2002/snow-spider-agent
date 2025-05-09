SELECT 
    SUBSTR(ipc_flat.value:"code"::string, 1, 4) AS "IPC4",
    COUNT(*) AS "PATENT_COUNT"
FROM 
    PATENTS.PATENTS.PUBLICATIONS p,
    LATERAL FLATTEN(input => p."ipc") ipc_flat
WHERE 
      p."country_code"   = 'US'
  AND p."kind_code"      = 'B2'           -- granted utility patents
  AND p."application_kind" = 'A'          -- utility (non‑design) applications
  AND p."grant_date" BETWEEN 20220601 AND 20220831   -- June‑August 2022
  AND ipc_flat.value:"code" IS NOT NULL
GROUP BY 
    "IPC4"
ORDER BY 
    "PATENT_COUNT" DESC NULLS LAST,
    "IPC4"
LIMIT 1;