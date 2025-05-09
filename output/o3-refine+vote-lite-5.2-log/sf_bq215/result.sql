WITH "CANDIDATE" AS (          -- US‑granted patents (B2) in 2015‑2018
    SELECT 
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
), "BACKWARD_CITATIONS" AS (   -- cited documents of each candidate patent
    SELECT 
        c."publication_number"                        AS "citing_pub",
        cit.value:"publication_number"::STRING        AS "cited_pub"
    FROM "CANDIDATE" c,
         LATERAL FLATTEN(INPUT => c."citation") cit
    WHERE cit.value:"publication_number" IS NOT NULL
), "CITED_IPCS" AS (           -- 4‑digit IPCs of all backward citations
    SELECT
        bc."citing_pub",
        SUBSTR(ipc.value:"code"::STRING, 1, 4)        AS "ipc4"
    FROM "BACKWARD_CITATIONS" bc
    JOIN PATENTS.PATENTS.PUBLICATIONS p2
      ON p2."publication_number" = bc."cited_pub"
    ,  LATERAL FLATTEN(INPUT => p2."ipc") ipc
    WHERE ipc.value:"code" IS NOT NULL
), "COUNTS_PER_IPC" AS (       -- n_k : occurrences of each IPC4
    SELECT
        "citing_pub",
        "ipc4",
        COUNT(*)                                   AS "n_k"
    FROM "CITED_IPCS"
    GROUP BY "citing_pub", "ipc4"
), "ORIGINALITY" AS (          -- originality = 1 - Σ n_k² / N²
    SELECT
        "citing_pub"                              AS "publication_number",
        1 - (SUM("n_k" * "n_k")::FLOAT 
             / POWER(SUM("n_k")::FLOAT, 2))       AS "originality_score"
    FROM "COUNTS_PER_IPC"
    GROUP BY "citing_pub"
    HAVING SUM("n_k") > 0
)
SELECT "publication_number"
FROM   "ORIGINALITY"
ORDER BY "originality_score" DESC NULLS LAST, "publication_number"
LIMIT 1;