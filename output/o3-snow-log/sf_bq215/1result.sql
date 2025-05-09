/* ----------  Highest-originality US-B2 patent granted 2015-2018 ---------- */

WITH candidate AS (     -- 1. Relevant US-B2 grants (2015-2018)
    SELECT  "publication_number" AS pubnum
    FROM    PATENTS.PATENTS.PUBLICATIONS
    WHERE   "country_code" = 'US'
      AND   "kind_code"    = 'B2'
      AND   "grant_date" BETWEEN 20150101 AND 20181231
),

backward AS (           -- 2. Backward patent citations
    SELECT  c.pubnum,
            cit.value:"publication_number"::TEXT AS cited_pub
    FROM    candidate c
    JOIN    PATENTS.PATENTS.PUBLICATIONS p
           ON p."publication_number" = c.pubnum
    CROSS   JOIN LATERAL FLATTEN(input => p."citation") cit
    WHERE   cit.value:"publication_number" IS NOT NULL
),

ipc_codes AS (          -- 3. IPC-4 codes of cited patents
    SELECT  b.pubnum,
            SUBSTR(ipc.value:"code"::TEXT, 1, 4) AS ipc4
    FROM    backward b
    JOIN    PATENTS.PATENTS.PUBLICATIONS cp
           ON cp."publication_number" = b.cited_pub
    CROSS   JOIN LATERAL FLATTEN(input => cp."ipc") ipc
    WHERE   ipc.value:"code" IS NOT NULL
),

ipc_cnt AS (            -- 4. Counts per IPC-4
    SELECT  pubnum,
            ipc4,
            COUNT(*) AS n_s
    FROM    ipc_codes
    GROUP BY pubnum, ipc4
),

stats AS (              -- 5. Σ n_s  and  Σ n_s²
    SELECT  pubnum,
            SUM(n_s)           AS N_total,
            SUM(n_s * n_s)     AS sum_sq
    FROM    ipc_cnt
    GROUP BY pubnum
),

orig AS (               -- 6. Originality score
    SELECT  pubnum,
            1 - (sum_sq / (N_total * N_total)::FLOAT) AS originality_score
    FROM    stats
    WHERE   N_total > 0
)

SELECT  pubnum AS "publication_number",
        originality_score
FROM    orig
ORDER BY originality_score DESC NULLS LAST
LIMIT 1;