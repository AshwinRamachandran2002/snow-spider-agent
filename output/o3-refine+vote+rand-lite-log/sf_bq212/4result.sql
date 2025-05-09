WITH filtered_pub AS (
    /* 1.  US utility patents (kind B2) granted Jun‑Sep 2022                */
    SELECT 
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'US'
      AND "kind_code"         = 'B2'          -- granted utility patent
      AND "application_kind"  = 'A'           -- utility (as opposed to design, etc.)
      AND "grant_date" BETWEEN 20220601 AND 20220930
),
ipc_expanded AS (
    /* 2.  explode the IPC array and keep the 4‑digit code                  */
    SELECT 
        fp."publication_number",
        UPPER(SUBSTR(f.value:"code"::string ,1,4)) AS ipc4
    FROM filtered_pub fp,
         LATERAL FLATTEN(input => fp."ipc") AS f
    WHERE f.value:"code" IS NOT NULL
),
ipc_per_patent AS (
    /* 3.  how many times each IPC4 occurs inside the same patent           */
    SELECT
        "publication_number",
        ipc4,
        COUNT(*) AS cnt
    FROM ipc_expanded
    GROUP BY "publication_number", ipc4
),
ranked_ipc AS (
    /* 4.  choose the most‑frequent IPC4 (ties → alphabetically first)      */
    SELECT
        "publication_number",
        ipc4,
        cnt,
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY cnt DESC, ipc4) AS rn
    FROM ipc_per_patent
),
patent_main_ipc AS (
    /* 5.  keep one IPC4 (the main one) per patent                          */
    SELECT
        "publication_number",
        ipc4
    FROM ranked_ipc
    WHERE rn = 1
),
ipc4_totals AS (
    /* 6.  how many patents share each main IPC4; keep those appearing ≥10  */
    SELECT
        ipc4,
        COUNT(*) AS patents_with_code
    FROM patent_main_ipc
    GROUP BY ipc4
    HAVING COUNT(*) >= 10
)
/* 7.  final list: patents whose main IPC4 shows up in ≥10 patents          */
SELECT 
    pmi."publication_number",
    pmi.ipc4
FROM patent_main_ipc pmi
JOIN ipc4_totals it
  ON pmi.ipc4 = it.ipc4
ORDER BY pmi.ipc4,
         pmi."publication_number";