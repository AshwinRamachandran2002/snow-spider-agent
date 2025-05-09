WITH main_ipc AS (          -- 1.  Derive each patent’s leading (most-frequent) IPC4
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4)      AS "ipc4",
        ROW_NUMBER() OVER (                       -- highest frequency per publication
            PARTITION BY p."publication_number"
            ORDER BY COUNT(*) DESC
        )                                         AS "rn"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN ( input => p."ipc" ) f
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'
      AND p."publication_date" BETWEEN 20220601 AND 20220930
    GROUP BY
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4)
),
high_ipc4 AS (            -- 2.  Keep IPC4 codes that lead ≥ 10 different patents
    SELECT
        "ipc4"
    FROM main_ipc
    WHERE "rn" = 1
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)
-- 3.  List publication numbers whose leading IPC4 qualifies
SELECT
    m."publication_number",
    m."ipc4"
FROM main_ipc  m
JOIN high_ipc4 h
  ON m."ipc4" = h."ipc4"
WHERE m."rn" = 1
ORDER BY
    m."ipc4",
    m."publication_number";