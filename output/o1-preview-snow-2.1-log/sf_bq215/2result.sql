WITH target_patents AS (
    SELECT "publication_number", "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US' 
      AND "kind_code" = 'B2' 
      AND "grant_date" BETWEEN 20150101 AND 20181231
      AND "citation" IS NOT NULL
),
backward_citations AS (
    SELECT t."publication_number" AS citing_patent, c.value:"publication_number"::STRING AS cited_publication_number
    FROM target_patents t, LATERAL FLATTEN(input => t."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
),
cited_ipc_codes AS (
    SELECT bc.citing_patent, ipc_cited.value:"code"::STRING AS ipc_code
    FROM backward_citations bc
    JOIN PATENTS.PATENTS.PUBLICATIONS pc ON bc.cited_publication_number = pc."publication_number"
    , LATERAL FLATTEN(input => pc."ipc") ipc_cited
    WHERE ipc_cited.value:"code" IS NOT NULL
),
cited_ipc4_codes AS (
    SELECT citing_patent, SUBSTR(ipc_code, 1, 4) AS ipc4_code
    FROM cited_ipc_codes
),
n_ik_table AS (
    SELECT citing_patent AS publication_number, ipc4_code, COUNT(*) AS n_ik
    FROM cited_ipc4_codes
    GROUP BY citing_patent, ipc4_code
),
n_i_table AS (
    SELECT bc.citing_patent AS publication_number, COUNT(*) AS n_i
    FROM backward_citations bc
    GROUP BY bc.citing_patent
),
originality_scores AS (
    SELECT n_ik_table.publication_number,
           ROUND(1 - SUM(POWER(CAST(n_ik_table.n_ik AS FLOAT) / n_i_table.n_i, 2)), 4) AS originality_score
    FROM n_ik_table
    JOIN n_i_table ON n_ik_table.publication_number = n_i_table.publication_number
    GROUP BY n_ik_table.publication_number
)
SELECT publication_number
FROM originality_scores
ORDER BY originality_score DESC NULLS LAST
LIMIT 1;