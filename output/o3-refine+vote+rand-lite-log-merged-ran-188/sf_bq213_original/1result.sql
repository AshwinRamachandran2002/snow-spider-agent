WITH ipc_per_patent AS (
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS ipc4
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(INPUT => p."ipc") AS f
    WHERE p."country_code" = 'US'
      AND p."kind_code"   = 'B2'          -- granted US patents (second or subsequent publication)
      AND p."application_kind" = 'A'      -- utility patents
      AND p."grant_date" BETWEEN 20220601 AND 20220831  -- June–August 2022
      AND f.value:"code" IS NOT NULL
)
SELECT
    ipc4,
    COUNT(DISTINCT "publication_number") AS patent_count
FROM ipc_per_patent
GROUP BY ipc4
ORDER BY patent_count DESC NULLS LAST, ipc4
LIMIT 1;