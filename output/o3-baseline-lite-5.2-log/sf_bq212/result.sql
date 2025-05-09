/* 1)  Filter for U.S. patents (utility) that were granted
       between 1 June 2022 and 30 September 2022, and whose
       kind‑code is “B2”.
   2)  For every patent, explode its IPC list, take the first
       four characters (“IPC4”), and count how often each IPC4
       occurs **within that patent**.
   3)  Keep the single IPC4 with the highest within‑patent count
       (ties broken alphabetically).
   4)  Count how many different patents share each of those
       “most‑frequent” IPC4 codes.
   5)  Return only those patents whose selected IPC4 appears in
       at least 10 patents in total.                                */

WITH filtered AS (   ------------------------------------------------- 1
    SELECT
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"     = 'US'
      AND "kind_code"        = 'B2'
      AND "grant_date" BETWEEN 20220601 AND 20220930
      AND ("application_kind" IS NULL OR "application_kind" = 'A')   -- utility
),

patent_ipc AS (      ----------------------------------------------- 2
    SELECT
        f."publication_number",
        SUBSTR(ipc_item.value:"code"::STRING,1,4) AS ipc4
    FROM filtered f,
         LATERAL FLATTEN(input => f."ipc") AS ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
),

ipc_counts AS (
    SELECT
        "publication_number",
        ipc4,
        COUNT(*) AS cnt_in_patent
    FROM patent_ipc
    GROUP BY "publication_number", ipc4
),

most_freq_per_patent AS (  ----------------------------------------- 3
    SELECT
        "publication_number",
        ipc4,
        cnt_in_patent,
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY cnt_in_patent DESC, ipc4) AS rn
    FROM ipc_counts
),

selected_ipc AS (   ----------------------------------------------- keep rn = 1
    SELECT
        "publication_number",
        ipc4
    FROM most_freq_per_patent
    WHERE rn = 1
),

ipc4_patent_totals AS (   ----------------------------------------- 4
    SELECT
        ipc4,
        COUNT(*) AS patents_with_code
    FROM selected_ipc
    GROUP BY ipc4
)

SELECT        --------------------------------------------- 5  result
    s."publication_number",
    s.ipc4
FROM selected_ipc      s
JOIN ipc4_patent_totals t
  ON s.ipc4 = t.ipc4
WHERE t.patents_with_code >= 10
ORDER BY s.ipc4, s."publication_number";