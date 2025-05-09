WITH "US_B2" AS (   -- 1.  Relevant U.S. utility-patent grants
    SELECT *
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"     = 'US'
      AND "kind_code"        = 'B2'
      AND "application_kind" = 'A'          -- utility patents
      AND "grant_date" BETWEEN 20220601 AND 20220930
),

"IPC_EXPANDED" AS (          -- 2.  Explode IPC list, keep 4-digit codes
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::string, 1, 4) AS "ipc4"
    FROM "US_B2" p,
         LATERAL FLATTEN(INPUT => p."ipc") f
    WHERE SUBSTR(f.value:"code"::string, 1, 4) IS NOT NULL
),

"IPC_COUNTS" AS (            -- 3.  Count occurrences per patent & IPC4
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*) AS "ipc4_count"
    FROM "IPC_EXPANDED"
    GROUP BY "publication_number", "ipc4"
),

"MOST_FREQ" AS (             -- 4.  Keep most-frequent IPC4 for each patent
    SELECT
        "publication_number",
        "ipc4",
        "ipc4_count",
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY "ipc4_count" DESC, "ipc4" ASC) AS "rn"
    FROM "IPC_COUNTS"
)

-- 5.  Return patents whose top IPC4 occurs ≥ 10 times
SELECT
    "publication_number",
    "ipc4" AS "ipc4_code"
FROM "MOST_FREQ"
WHERE "rn" = 1
  AND "ipc4_count" >= 10
ORDER BY "publication_number" NULLS LAST;