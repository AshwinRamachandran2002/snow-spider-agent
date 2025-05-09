WITH us_b2_1518 AS (                    -- 1. US B2-kind patents granted 2015-2018
    SELECT "publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS
    WHERE  "country_code" = 'US'
      AND  "kind_code"    = 'B2'
      AND  "grant_date" BETWEEN 20150101 AND 20181231
),

citations AS (                          -- 2. backward citations
    SELECT  c."publication_number"               AS "citing_pub",
            f.value:"publication_number"::STRING AS "cited_pub"
    FROM    PATENTS.PATENTS.PUBLICATIONS c,
            LATERAL FLATTEN(input => c."citation") f
    WHERE   c."publication_number" IN (SELECT "publication_number" FROM us_b2_1518)
      AND   f.value:"publication_number" IS NOT NULL
),

ipc4_of_cited AS (                      -- 3. 4-digit IPC of cited patents
    SELECT  cit."citing_pub",
            SUBSTR(ipc_u.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM    citations                         cit
    JOIN    PATENTS.PATENTS.PUBLICATIONS      p
           ON p."publication_number" = cit."cited_pub",
            LATERAL FLATTEN(input => p."ipc") ipc_u
),

ipc_counts AS (                          -- 4. frequency per (citing, IPC4)
    SELECT  "citing_pub",
            "ipc4",
            COUNT(*) AS freq_k
    FROM    ipc4_of_cited
    GROUP BY "citing_pub", "ipc4"
),

agg AS (                                 -- 5. aggregates for originality
    SELECT  "citing_pub",
            SUM(freq_k * freq_k) AS sum_sq,
            SUM(freq_k)          AS tot
    FROM    ipc_counts
    GROUP BY "citing_pub"
),

originality AS (                         -- 6. originality score
    SELECT  "citing_pub"                             AS "publication_number",
            1 - (sum_sq::FLOAT / (tot * tot))        AS "originality_score"
    FROM    agg
)

SELECT  "publication_number",
        "originality_score"
FROM    originality
ORDER BY "originality_score" DESC NULLS LAST
LIMIT 1;