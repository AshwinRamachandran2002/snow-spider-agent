WITH filtered_publications AS (        -- 1.  Select U.S. B2‑granted utility patents (Jun‑Sep 2022)
    SELECT
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"    = 'US'
      AND "kind_code"       = 'B2'
      AND "publication_date" BETWEEN 20220601 AND 20220930
      AND "application_kind" IN ('A','U')          -- utility patents
),
ipc_expanded AS (                      -- 2.  Explode IPC list and keep 4‑digit codes
    SELECT
        fp."publication_number",
        SUBSTR( fl.value:"code"::STRING , 1 , 4 )          AS ipc4
    FROM filtered_publications fp,
         LATERAL FLATTEN( INPUT => fp."ipc") fl
    WHERE fl.value:"code" IS NOT NULL
),
ipc_counts AS (                        -- 3.  Count occurrences of every IPC4 per patent
    SELECT
        "publication_number",
        ipc4,
        COUNT(*) AS ipc4_count
    FROM ipc_expanded
    GROUP BY "publication_number", ipc4
),
most_frequent_ipc4 AS (                -- 4.  Keep the most‑frequent IPC4 of each patent
    SELECT
        ic."publication_number",
        ic.ipc4,
        ic.ipc4_count,
        RANK() OVER (PARTITION BY ic."publication_number"
                     ORDER BY ic.ipc4_count DESC, ic.ipc4) AS rnk
    FROM ipc_counts ic
),
selected_patents AS (                  -- 5.  Most‑frequent IPC4 appears ≥ 10 times
    SELECT
        "publication_number",
        ipc4
    FROM most_frequent_ipc4
    WHERE rnk = 1
      AND ipc4_count >= 10
)
SELECT
    "publication_number",
    ipc4                                -- 6.  Final list
FROM selected_patents
ORDER BY "publication_number";