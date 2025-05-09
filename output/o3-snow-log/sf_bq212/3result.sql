/*  Most–frequent 4-digit IPC code for each U.S. B2 utility patent
    granted between 1 Jun 2022 and 30 Sep 2022.
    Only patents whose top IPC-4 occurs ≥10 times are returned. */

WITH filtered_pubs AS (          -- Step 1: restrict to the target patents
    SELECT
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'US'
      AND "kind_code"         = 'B2'
      AND "application_kind"  = 'A'          -- utility‐patent kind
      AND "grant_date" BETWEEN 20220601 AND 20220930
),

ipc_expanded AS (               -- Step 2: explode IPC array and keep IPC-4
    SELECT
        fp."publication_number",
        SUBSTR( ipc_it.value:"code"::STRING , 1 , 4 ) AS "IPC4"
    FROM filtered_pubs fp,
         LATERAL FLATTEN( INPUT => fp."ipc" ) ipc_it
    WHERE ipc_it.value:"code" IS NOT NULL
),

ipc_counts AS (                 -- Step 3: count occurrences of each IPC-4 per patent
    SELECT
        "publication_number",
        "IPC4",
        COUNT(*) AS "ipc4_count"
    FROM ipc_expanded
    GROUP BY "publication_number", "IPC4"
),

ranked AS (                     -- Step 4: keep the most-frequent IPC-4 per patent
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number"
            ORDER BY "ipc4_count" DESC, "IPC4"
        ) AS rn
    FROM ipc_counts
)

SELECT                          -- Final list
    "publication_number",
    "IPC4",
    "ipc4_count"
FROM ranked
WHERE rn = 1
  AND "ipc4_count" >= 10        -- top IPC-4 appears ≥10 times
ORDER BY "publication_number" NULLS LAST;