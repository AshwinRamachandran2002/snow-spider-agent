WITH us_b2 AS (   -- United-States utility patents (B2) granted Jun-Sep 2022
    SELECT
        "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'US'
      AND "kind_code"         = 'B2'
      AND "application_kind"  = 'A'        -- utility patents
      AND "grant_date" BETWEEN 20220601 AND 20220930
),

ipc_counts AS (    -- count occurrences of every 4-digit IPC code within each patent
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 0, 4)           AS "IPC4",
        COUNT(*)                                       AS "ipc4_cnt"
    FROM us_b2               p
    JOIN PATENTS.PATENTS.PUBLICATIONS pub
      ON pub."publication_number" = p."publication_number"
       , LATERAL FLATTEN(input => pub."ipc") f
    GROUP BY p."publication_number", "IPC4"
),

main_ipc AS (      -- keep the single most-frequent IPC4 per patent (ties broken arbitrarily)
    SELECT
        "publication_number",
        "IPC4",
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY "ipc4_cnt" DESC) AS rn
    FROM ipc_counts
),

main_selected AS ( -- patents with their main IPC4
    SELECT "publication_number", "IPC4"
    FROM main_ipc
    WHERE rn = 1
),

freq_ipc4 AS (     -- IPC4 codes that serve as the main code for ≥10 patents
    SELECT "IPC4"
    FROM main_selected
    GROUP BY "IPC4"
    HAVING COUNT(*) >= 10
)

-- final list: publication numbers & their (frequent) main IPC4
SELECT
    m."publication_number",
    m."IPC4"
FROM main_selected m
JOIN freq_ipc4     f
  ON m."IPC4" = f."IPC4"
ORDER BY m."IPC4" ASC, m."publication_number" ASC;