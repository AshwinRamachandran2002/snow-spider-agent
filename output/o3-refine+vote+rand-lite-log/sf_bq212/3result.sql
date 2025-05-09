WITH us_b2_2022 AS (           -- 1. US utility patents (kind B2) granted Jun‑Sep 2022
    SELECT
        p."publication_number",
        p."ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         = 'B2'
      AND p."application_kind"  = 'A'      -- utility patents
      AND p."grant_date" BETWEEN 20220601  -- 1 Jun 2022
                           AND 20220930    -- 30 Sep 2022
),
ipc_flat AS (                  -- 2. explode IPC list and keep 4‑digit codes
    SELECT
        u."publication_number",
        SUBSTR(f.value:"code"::STRING,1,4) AS ipc4
    FROM us_b2_2022 AS u,
         LATERAL FLATTEN(input => u."ipc") AS f
    WHERE f.value:"code" IS NOT NULL
),
ipc_counts AS (                -- 3. count occurrences per patent & IPC4
    SELECT
        "publication_number",
        ipc4,
        COUNT(*)                                     AS ipc4_count,
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number"
            ORDER BY COUNT(*) DESC, ipc4            -- pick most‑frequent IPC4
        )                                           AS rn
    FROM ipc_flat
    GROUP BY "publication_number", ipc4
)
-- 4. return patents whose top IPC4 appears ≥10 times
SELECT
    "publication_number",
    ipc4
FROM ipc_counts
WHERE rn = 1
  AND ipc4_count >= 10
ORDER BY "publication_number";