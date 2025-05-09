WITH us_b2_2022 AS (        -- 1.  limit to US utility patents (kind B2) granted Jun-Sep 2022
    SELECT 
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "application_kind" = 'A'          -- utility patent
      AND "grant_date" BETWEEN 20220601 AND 20220930
),

ipc_flat AS (               -- 2.  explode IPC list and keep the first 4 characters
    SELECT
        u."publication_number",
        SUBSTR(f.value:"code"::string, 1, 4) AS ipc4
    FROM us_b2_2022 u,
         LATERAL FLATTEN(input => u."ipc") f
    WHERE f.value:"code" IS NOT NULL
),

ipc4_counts AS (            -- 3.  count occurrences of each 4-digit IPC within a patent
    SELECT
        "publication_number",
        ipc4,
        COUNT(*) AS ipc4_count
    FROM ipc_flat
    GROUP BY "publication_number", ipc4
),

most_freq_ipc4 AS (         -- 4.  pick the most frequent IPC4 per patent
    SELECT
        "publication_number",
        ipc4,
        ipc4_count,
        ROW_NUMBER() OVER (PARTITION BY "publication_number" 
                           ORDER BY ipc4_count DESC, ipc4) AS rn
    FROM ipc4_counts
)

-- 5.  return patents whose top IPC4 appears ≥10 times
SELECT
    "publication_number",
    ipc4  AS ipc4_code
FROM most_freq_ipc4
WHERE rn = 1
  AND ipc4_count >= 10
ORDER BY "publication_number";