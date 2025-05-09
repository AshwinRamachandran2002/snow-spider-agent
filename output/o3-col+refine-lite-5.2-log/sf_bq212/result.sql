WITH ipc_counts AS (   -- unnest IPC array and count occurrences per patent & IPC4
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4",
        COUNT(*)                              AS "cnt_per_patent_ipc4"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."ipc") AS f
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         = 'B2'
      AND p."application_kind"  = 'A'
      AND p."publication_date" BETWEEN 20220601 AND 20220930
    GROUP BY
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4)
), dominant_ipc4 AS (   -- keep only the most‑frequent IPC4 per patent
    SELECT
        ic."publication_number",
        ic."ipc4",
        ROW_NUMBER() OVER (PARTITION BY ic."publication_number"
                           ORDER BY ic."cnt_per_patent_ipc4" DESC,
                                    ic."ipc4") AS rn
    FROM ipc_counts ic
), popular_ipc4 AS (    -- IPC4 codes that are dominant for ≥10 patents
    SELECT
        d."ipc4"
    FROM dominant_ipc4 d
    WHERE d.rn = 1
    GROUP BY d."ipc4"
    HAVING COUNT(*) >= 10
)
SELECT
    d."publication_number",
    d."ipc4"
FROM dominant_ipc4 d
JOIN popular_ipc4 p
  ON d."ipc4" = p."ipc4"
WHERE d.rn = 1
ORDER BY
    d."ipc4",
    d."publication_number";