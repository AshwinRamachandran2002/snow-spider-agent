/*  Most-frequent IPC4 per U.S. B2 utility patent (Jun–Sep 2022),
    then keep only those IPC4s that occur in ≥10 different patents           */

WITH per_code AS (   -- explode every IPC code and keep the first 4 chars
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'
      AND p."application_kind" = 'A'
      AND p."publication_date" BETWEEN 20220601 AND 20220930
),
ranked AS (          -- count occurrences of each IPC4 within each patent
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*) AS "ipc4_cnt",
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY COUNT(*) DESC, "ipc4") AS "rn"
    FROM per_code
    GROUP BY "publication_number", "ipc4"
),
main_ipc AS (        -- one “main” IPC4 per patent (most frequent)
    SELECT "publication_number", "ipc4"
    FROM   ranked
    WHERE  "rn" = 1
),
freq_ipc AS (        -- IPC4 codes appearing in ≥10 different patents
    SELECT "ipc4"
    FROM   main_ipc
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)
SELECT
    m."publication_number",
    m."ipc4"
FROM   main_ipc m
JOIN   freq_ipc f
  ON   m."ipc4" = f."ipc4"
ORDER BY m."publication_number";