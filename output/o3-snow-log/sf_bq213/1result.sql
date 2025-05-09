WITH ipc_flat AS (
    SELECT
        "publication_number",
        SUBSTR(ipc_f.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM PATENTS.PATENTS.PUBLICATIONS
         , LATERAL FLATTEN(input => "ipc") AS ipc_f
    WHERE "country_code"      = 'US'
      AND "kind_code"         = 'B2'
      AND "application_kind"  = 'A'          -- utility patent grants
      AND "grant_date" BETWEEN 20220601 AND 20220831   -- June-August 2022
)
SELECT
    "ipc4",
    COUNT(DISTINCT "publication_number") AS "patent_count"
FROM ipc_flat
GROUP BY "ipc4"
ORDER BY "patent_count" DESC NULLS LAST
LIMIT 1;