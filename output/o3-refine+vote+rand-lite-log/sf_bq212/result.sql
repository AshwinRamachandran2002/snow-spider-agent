WITH filtered_pubs AS (
    SELECT *
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'          -- United States patents
      AND "kind_code"   = 'B2'           -- Utility patents, granted (B2)
      AND "grant_date" BETWEEN 20220601  -- 1 June 2022
                          AND 20220930   -- 30 Sept 2022
),
ipc_expanded AS (                          -- unpack IPC array
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM filtered_pubs p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE f.value:"code" IS NOT NULL
),
ipc_counts AS (                            -- count IPC‑4 occurrences per patent
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*) AS cnt
    FROM ipc_expanded
    GROUP BY "publication_number", "ipc4"
),
most_freq_ipc AS (                         -- pick the most frequent IPC‑4
    SELECT
        "publication_number",
        "ipc4",
        cnt,
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY cnt DESC, "ipc4") AS rn
    FROM ipc_counts
)
SELECT
    "publication_number",
    "ipc4"
FROM most_freq_ipc
WHERE rn = 1                -- keep only the top‑frequency IPC‑4 for each patent
  AND cnt >= 10             -- require it to appear at least 10 times
ORDER BY "publication_number";