WITH filtered_pubs AS (   -- 1)  US utility (A), B2 grants between 1-Jun & 30-Sep 2022
    SELECT 
        p."publication_number",
        p."ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."country_code"      = 'US'
      AND p."kind_code"        ILIKE '%B2%'
      AND p."grant_date"        BETWEEN 20220601 AND 20220930
      AND p."application_kind"  = 'A'
),                                                              
ipc_per_pub AS (            -- 2)  explode IPC array, keep 4-digit IPC code
    SELECT  
        fp."publication_number",
        SUBSTR(f.value::VARIANT:"code"::STRING,1,4) AS "ipc4"
    FROM filtered_pubs fp,
         LATERAL FLATTEN (INPUT => fp."ipc") f
),                                                              
top_ipc4_per_pub AS (       -- 3)  most-frequent IPC4 within each publication
    SELECT
        ip."publication_number",
        ip."ipc4",
        COUNT(*) AS "cnt_within_pub",
        ROW_NUMBER() OVER (PARTITION BY ip."publication_number"
                           ORDER BY COUNT(*) DESC, ip."ipc4") AS "rnk"
    FROM ipc_per_pub ip
    GROUP BY ip."publication_number", ip."ipc4"
),                                                              
hot_ipc4 AS (               -- 4)  IPC4 codes appearing as a top code in ≥10 publications
    SELECT 
        "ipc4"
    FROM top_ipc4_per_pub
    WHERE "rnk" = 1
    GROUP BY "ipc4"
    HAVING COUNT(DISTINCT "publication_number") >= 10
)                                                               
-- 5)  final list: publication numbers & their (popular) top IPC4 codes
SELECT  
    t."publication_number",
    t."ipc4"
FROM top_ipc4_per_pub t
JOIN hot_ipc4 h
  ON t."ipc4" = h."ipc4"
WHERE t."rnk" = 1
ORDER BY t."ipc4", t."publication_number";