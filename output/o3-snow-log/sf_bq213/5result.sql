WITH "US_B2_JunAug22" AS (
    SELECT 
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"    = 'B2'
      AND "publication_date" BETWEEN 20220601 AND 20220831      -- June-August 2022 grants
),
"IPC4_PER_PATENT" AS (           -- one row per patent-IPC4 pair
    SELECT DISTINCT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM "US_B2_JunAug22" p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE f.value:"code" IS NOT NULL
),
"IPC4_COUNTS" AS (
    SELECT 
        "ipc4",
        COUNT(DISTINCT "publication_number") AS "patent_count"
    FROM "IPC4_PER_PATENT"
    GROUP BY "ipc4"
)
SELECT 
    "ipc4",
    "patent_count"
FROM "IPC4_COUNTS"
ORDER BY "patent_count" DESC NULLS LAST
LIMIT 1;