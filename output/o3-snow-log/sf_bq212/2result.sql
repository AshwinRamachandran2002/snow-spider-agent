/* ----------------------------------------------------------
   1)  Select U.S. utility patents with kind-code “B2”
       granted between 1-Jun-2022 and 30-Sep-2022
   2)  Explode the IPC array, keep the first 4 characters
   3)  For every patent pick the IPC4 that occurs most often
       (ties resolved alphabetically)
   4)  Keep only those IPC4 codes that are assigned to
       10 or more different patents
   5)  Return publication numbers and their IPC4
----------------------------------------------------------*/
WITH us_b2 AS (
    SELECT
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'US'
      AND "kind_code"         = 'B2'
      AND "application_kind"  = 'A'              -- utility
      AND "grant_date" BETWEEN 20220601 AND 20220930
),
ipc_flat AS (   -- explode IPC list
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING,1,4) AS ipc4
    FROM us_b2 p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE f.value:"code" IS NOT NULL
),
ipc_rank AS (   -- count occurrences per patent & rank
    SELECT
        "publication_number",
        ipc4,
        COUNT(*) AS occs,
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number"
            ORDER BY COUNT(*) DESC, ipc4 ASC
        ) AS rn
    FROM ipc_flat
    GROUP BY "publication_number", ipc4
),
main_ipc AS (   -- keep most-frequent IPC4 per patent
    SELECT
        "publication_number",
        ipc4
    FROM ipc_rank
    WHERE rn = 1
),
freq_ipc AS (   -- IPC4 codes used by ≥10 patents
    SELECT
        ipc4,
        COUNT(*) AS n_patents
    FROM main_ipc
    GROUP BY ipc4
    HAVING COUNT(*) >= 10
)
SELECT
    m."publication_number",
    m.ipc4
FROM main_ipc m
JOIN freq_ipc f
  ON m.ipc4 = f.ipc4
ORDER BY
    m.ipc4,
    m."publication_number" NULLS LAST;