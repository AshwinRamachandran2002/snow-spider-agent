WITH backward_citations AS (
    -- explode backward citations for each US-B2 patent granted 2015-2018
    SELECT
        p."publication_number"                       AS "citing_pub",
        c.value:"publication_number"::STRING         AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") c
    WHERE p."country_code" = 'US'
      AND p."kind_code"    = 'B2'
      AND p."grant_date"  BETWEEN 20150101 AND 20181231
      AND c.value:"publication_number" IS NOT NULL
),
cited_ipc4 AS (
    -- obtain 4-digit IPC codes of all cited publications
    SELECT
        bc."citing_pub",
        SUBSTR(ipc_item.value:"code"::STRING, 1, 4)  AS "ipc4"
    FROM backward_citations bc
    JOIN PATENTS.PATENTS.PUBLICATIONS cited
      ON cited."publication_number" = bc."cited_pub",
    LATERAL FLATTEN(input => cited."ipc") ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
),
n_by_class AS (
    -- count occurrences per IPC4 for each citing patent
    SELECT
        "citing_pub",
        "ipc4",
        COUNT(*) AS n_i
    FROM cited_ipc4
    GROUP BY "citing_pub", "ipc4"
),
sums AS (
    -- compute N and Σ n_i² for originality formula
    SELECT
        "citing_pub"                     AS "publication_number",
        SUM(n_i)           AS N_int,
        SUM(POWER(n_i,2))  AS sum_sq_int
    FROM n_by_class
    GROUP BY "citing_pub"
    HAVING SUM(n_i) > 0
),
originality_scores AS (
    SELECT
        "publication_number",
        1 - (sum_sq_int::FLOAT / POWER(N_int::FLOAT, 2)) AS originality
    FROM sums
)
-- retrieve the patent with the highest originality score
SELECT
    "publication_number",
    originality
FROM originality_scores
ORDER BY originality DESC NULLS LAST
LIMIT 1;