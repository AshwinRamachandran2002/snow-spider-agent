WITH filtered_pubs AS (      -- 1) US B2 utility patents granted Jun-Sep 2022
    SELECT 
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"    = 'B2'
      AND "grant_date" BETWEEN 20220601 AND 20220930
),

ipc_expanded AS (            -- 2) explode IPC list, keep 4-digit codes
    SELECT 
        fp."publication_number",
        LEFT( ipc_item.value:"code"::string , 4) AS "ipc4"
    FROM filtered_pubs fp,
         LATERAL FLATTEN(INPUT => fp."ipc") ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
),

ipc_freq AS (                -- 3) frequency of each IPC4 per patent
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*) AS cnt,
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY COUNT(*) DESC, "ipc4") AS rn
    FROM ipc_expanded
    GROUP BY "publication_number", "ipc4"
),

main_ipc AS (                -- 4) most-frequent IPC4 for every patent
    SELECT
        "publication_number",
        "ipc4"
    FROM ipc_freq
    WHERE rn = 1
),

ipc4_totals AS (             -- 5) IPC4 codes appearing ≥10 times
    SELECT
        "ipc4",
        COUNT(*) AS appearances
    FROM main_ipc
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)

-- 6) final list of patents whose main IPC4 meets the ≥10 criterion
SELECT
    mi."publication_number",
    mi."ipc4"
FROM main_ipc  mi
JOIN ipc4_totals it
  ON mi."ipc4" = it."ipc4"
ORDER BY mi."ipc4", mi."publication_number" NULLS LAST;