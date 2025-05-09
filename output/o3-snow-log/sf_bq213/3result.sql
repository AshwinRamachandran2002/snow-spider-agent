WITH "FILTERED_PUBS" AS (
    SELECT 
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'US'
      AND "kind_code"         = 'B2'          -- granted B2 patents
      AND "application_kind"  = 'A'           -- utility patents
      AND "grant_date" BETWEEN 20220601 AND 20220831   -- June-Aug 2022
), 
"IPC4_PER_PATENT" AS (
    SELECT
        fp."publication_number",
        SUBSTR(it.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM "FILTERED_PUBS" fp,
         LATERAL FLATTEN(input => fp."ipc") it
    WHERE it.value:"code" IS NOT NULL
)
SELECT 
    "ipc4",
    COUNT(DISTINCT "publication_number") AS "patent_count"
FROM "IPC4_PER_PATENT"
GROUP BY "ipc4"
ORDER BY "patent_count" DESC NULLS LAST
LIMIT 1;