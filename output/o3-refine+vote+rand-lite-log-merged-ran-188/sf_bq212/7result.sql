/*  Most–frequent IPC4 per U.S. B2-granted patent (Jun–Sep 2022) 
    and only keep patents whose selected IPC4 occurs in ≥10 patents  */

WITH ipc_per_pub AS (
    SELECT  
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."ipc") f
    WHERE p."country_code" = 'US'
      AND p."kind_code"   = 'B2'
      AND p."publication_date" BETWEEN 20220601 AND 20220930
), ranked_ipc AS (
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*)                                           AS "ipc4_freq",
        RANK() OVER (PARTITION BY "publication_number"
                     ORDER BY COUNT(*) DESC, "ipc4")       AS "rnk"
    FROM ipc_per_pub
    GROUP BY "publication_number", "ipc4"
), top_ipc AS (          -- most-frequent IPC4 per patent
    SELECT * 
    FROM ranked_ipc
    WHERE "rnk" = 1
), ipc_counts AS (       -- IPC4 codes appearing in ≥10 patents
    SELECT 
        "ipc4",
        COUNT(*) AS "patent_count"
    FROM top_ipc
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)
SELECT 
    t."publication_number",
    t."ipc4"
FROM top_ipc      t
JOIN ipc_counts   c  ON t."ipc4" = c."ipc4"
ORDER BY t."publication_number";