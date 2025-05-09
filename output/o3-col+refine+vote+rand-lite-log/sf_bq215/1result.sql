WITH us_b2_2015_18 AS (   -- 1) target patents
    SELECT 
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"     = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),
citations AS (            -- 2) their backward citations
    SELECT 
        up."publication_number"                     AS citing_pub,
        f.value:"publication_number"::STRING        AS cited_pub
    FROM us_b2_2015_18  up,
         LATERAL FLATTEN(input => up."citation") f
    WHERE f.value:"publication_number" IS NOT NULL
),
cited_ipc AS (            -- 3) 4-digit IPC codes of cited patents
    SELECT 
        c.citing_pub,
        c.cited_pub,
        SUBSTR(ipc_f.value:"code"::STRING,1,4)      AS ipc4
    FROM citations c
    JOIN PATENTS.PATENTS.PUBLICATIONS p
          ON p."publication_number" = c.cited_pub
    ,    LATERAL FLATTEN(input => p."ipc") ipc_f
    WHERE SUBSTR(ipc_f.value:"code"::STRING,1,4) IS NOT NULL
),
code_counts AS (          -- 4) n_k : occurrences per IPC4
    SELECT 
        citing_pub,
        ipc4,
        COUNT(DISTINCT cited_pub)                   AS n_k
    FROM cited_ipc
    GROUP BY citing_pub, ipc4
),
totals AS (               -- 5) N : total occurrences
    SELECT 
        citing_pub,
        SUM(n_k)                                    AS N
    FROM code_counts
    GROUP BY citing_pub
),
orig_scores AS (          -- 6) originality = 1 - Σ (n_k / N)^2
    SELECT 
        c.citing_pub,
        1 - SUM( POWER( c.n_k::FLOAT / t.N , 2) )   AS originality
    FROM code_counts c
    JOIN totals t
          ON t.citing_pub = c.citing_pub
    GROUP BY c.citing_pub
)
SELECT 
    citing_pub           AS "publication_number",
    originality
FROM orig_scores
ORDER BY originality DESC NULLS LAST
LIMIT 1;