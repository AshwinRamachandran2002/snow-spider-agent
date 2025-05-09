WITH focal AS (                                             -- US-9741766-B2 and its filing year
    SELECT
        "publication_number",
        SUBSTR("filing_date",1,4) AS filing_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
),
focal_ipc AS (                                              -- 4-digit IPC codes of the focal patent
    SELECT DISTINCT SUBSTR(ipc_f.value:"code"::STRING,1,4) AS ipc4
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS fp,
         LATERAL FLATTEN(input => fp."ipc") ipc_f
    WHERE fp."publication_number" = 'US-9741766-B2'
),
candidates AS (                                             -- patents filed in the same year
    SELECT
        p."publication_number",
        COUNT(DISTINCT SUBSTR(ipc_c.value:"code"::STRING,1,4)) AS overlap_cnt
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
         JOIN focal f
           ON SUBSTR(p."filing_date",1,4) = f.filing_year
         , LATERAL FLATTEN(input => p."ipc") ipc_c
    WHERE p."publication_number" <> 'US-9741766-B2'
      AND SUBSTR(ipc_c.value:"code"::STRING,1,4) IN (SELECT ipc4 FROM focal_ipc)
    GROUP BY p."publication_number"
)
SELECT
    "publication_number"
FROM candidates
ORDER BY overlap_cnt DESC NULLS LAST, "publication_number"
LIMIT 5;