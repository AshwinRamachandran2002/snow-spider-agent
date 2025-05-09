WITH main_ipc4 AS (          -- Step 1: determine each patent’s most-frequent 4-digit IPC
    SELECT
        p."publication_number",
        SUBSTR(ipc_f.value:"code"::STRING, 1, 4)                       AS "ipc4",
        COUNT(*)                                                       AS "ipc4_count",
        RANK() OVER (PARTITION BY p."publication_number"
                     ORDER BY COUNT(*) DESC,
                              SUBSTR(ipc_f.value:"code"::STRING, 1, 4)) AS "rnk"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."ipc") ipc_f
    WHERE p."country_code"      = 'US'        -- United States
      AND p."kind_code"         = 'B2'        -- granted utility patents
      AND p."grant_date" BETWEEN 20220601 AND 20220930   -- Jun–Sep 2022 (YYYYMMDD)
      AND p."application_kind"  = 'A'         -- utility applications
    GROUP BY
        p."publication_number",
        SUBSTR(ipc_f.value:"code"::STRING, 1, 4)
),

qualifying_ipc4 AS (          -- Step 2: keep IPC4s appearing in ≥ 10 different patents
    SELECT "ipc4"
    FROM   main_ipc4
    WHERE  "rnk" = 1
    GROUP  BY "ipc4"
    HAVING COUNT(*) >= 10
)

-- Step 3: list publication numbers whose main IPC4 passes the 10-patent threshold
SELECT
    m."publication_number",
    m."ipc4"
FROM   main_ipc4        m
JOIN   qualifying_ipc4  q
       ON m."ipc4" = q."ipc4"
WHERE  m."rnk" = 1
ORDER  BY m."ipc4", m."publication_number";