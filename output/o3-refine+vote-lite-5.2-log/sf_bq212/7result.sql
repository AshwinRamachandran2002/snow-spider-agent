WITH filtered AS (   -- 1.  US utility patents (kind B2) granted Jun‑Sep 2022
    SELECT
        p."publication_number",
        p."ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         = 'B2'          -- granted utility patents
      AND p."application_kind"  = 'A'           -- utility applications
      AND p."grant_date" BETWEEN 20220601 AND 20220930
),
ipc_counts AS (       -- 2.  count occurrences of every 4‑digit IPC in each patent
    SELECT
        f."publication_number",
        SUBSTR(ipc_item.value:"code"::STRING,1,4) AS "ipc4",
        COUNT(*) AS "cnt"
    FROM filtered f
    CROSS JOIN LATERAL FLATTEN(input => f."ipc") ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
    GROUP BY
        f."publication_number",
        "ipc4"
),
ranked AS (           -- 3.  keep the most‑frequent IPC4 for each patent
    SELECT
        ic."publication_number",
        ic."ipc4",
        ic."cnt",
        ROW_NUMBER() OVER (
            PARTITION BY ic."publication_number"
            ORDER BY ic."cnt" DESC, ic."ipc4"
        ) AS rn
    FROM ipc_counts ic
),
top_ipc AS (          -- 4.  patents whose top IPC4 appears ≥ 10 times
    SELECT
        "publication_number",
        "ipc4"
    FROM ranked
    WHERE rn = 1
      AND "cnt" >= 10
)
SELECT
    "publication_number",
    "ipc4"
FROM top_ipc
ORDER BY
    "publication_number";