WITH filtered AS (  -- U.S. B2 grants (utility patents) between 1 Jun 2022 and 30 Sep 2022
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'
      AND p."application_kind" = 'A'       -- utility patent applications
      AND p."publication_date" BETWEEN 20220601 AND 20220930
),
ipc_counts AS (      -- count occurrences of each IPC4 within each patent
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*) AS "ipc4_cnt"
    FROM filtered
    GROUP BY "publication_number", "ipc4"
),
main_ipc AS (        -- choose the most‑frequent IPC4 per patent
    SELECT
        "publication_number",
        "ipc4",
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number"
            ORDER BY "ipc4_cnt" DESC, "ipc4"
        ) AS "rnk"
    FROM ipc_counts
),
ipc4_with_10 AS (    -- IPC4 codes that are the main code for ≥10 patents
    SELECT "ipc4"
    FROM main_ipc
    WHERE "rnk" = 1
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)
SELECT
    m."publication_number",
    m."ipc4"
FROM main_ipc m
JOIN ipc4_with_10 i
  ON m."ipc4" = i."ipc4"
WHERE m."rnk" = 1
ORDER BY m."ipc4", m."publication_number";