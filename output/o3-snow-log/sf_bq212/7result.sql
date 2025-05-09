/*  Final corrected query  */

WITH filtered AS (   /* 1. IPC4 occurrences in the target patents */
    SELECT
        pub."publication_number",
        UPPER(LEFT(ipc_f.value:"code"::STRING, 4)) AS ipc4
    FROM PATENTS.PATENTS.PUBLICATIONS AS pub,
         LATERAL FLATTEN(INPUT => pub."ipc") AS ipc_f
    WHERE pub."country_code" = 'US'
      AND pub."kind_code"    = 'B2'
      AND pub."grant_date"  BETWEEN 20220601 AND 20220930
),

ranked AS (          /* 2. Most-frequent IPC4 per patent */
    SELECT
        "publication_number",
        ipc4,
        COUNT(*) AS ipc4_count,
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number"
            ORDER BY COUNT(*) DESC, ipc4
        ) AS rn
    FROM filtered
    GROUP BY "publication_number", ipc4
),

dominant AS (        /* 3. One dominant IPC4 per patent */
    SELECT "publication_number", ipc4
    FROM ranked
    WHERE rn = 1
),

ipc4_totals AS (     /* 4. IPC4 codes that occur in ≥ 10 patents */
    SELECT ipc4, COUNT(*) AS patent_cnt
    FROM dominant
    GROUP BY ipc4
    HAVING COUNT(*) >= 10
)

SELECT                /* 5. Result */
    d."publication_number",
    d.ipc4
FROM dominant    AS d
JOIN ipc4_totals AS t
  ON d.ipc4 = t.ipc4
ORDER BY
    d.ipc4,
    d."publication_number";