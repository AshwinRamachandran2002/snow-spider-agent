WITH us_patents AS (
    SELECT
        p."publication_number"
    FROM
        PATENTS.PATENTS.PUBLICATIONS p
    WHERE
        p."country_code" = 'US'
        AND p."kind_code" = 'B2'
        AND p."grant_date" BETWEEN 20150101 AND 20181231
),
citing_citations AS (
    SELECT
        t."publication_number" AS citing_pub_num,
        cit.value:"publication_number"::STRING AS cited_publication_number
    FROM
        us_patents t
        JOIN PATENTS.PATENTS.PUBLICATIONS p ON t."publication_number" = p."publication_number",
        LATERAL FLATTEN(input => p."citation") cit
    WHERE
        cit.value:"publication_number" IS NOT NULL
),
cited_ipc_codes AS (
    SELECT
        cp."publication_number" AS cited_publication_number,
        SUBSTR(ipc.value:"code"::STRING, 1, 4) AS cited_ipc4_code
    FROM
        PATENTS.PATENTS.PUBLICATIONS cp,
        LATERAL FLATTEN(input => cp."ipc") ipc
    WHERE
        ipc.value:"code" IS NOT NULL
),
citations_with_ipc AS (
    SELECT
        cc.citing_pub_num,
        cc.cited_publication_number,
        cic.cited_ipc4_code
    FROM
        citing_citations cc
        LEFT JOIN cited_ipc_codes cic ON cc.cited_publication_number = cic.cited_publication_number
),
n_i AS (
    SELECT
        citing_pub_num,
        COUNT(DISTINCT cited_publication_number) AS n_i
    FROM
        citing_citations
    GROUP BY
        citing_pub_num
),
n_i_k AS (
    SELECT
        citing_pub_num,
        cited_ipc4_code,
        COUNT(DISTINCT cited_publication_number) AS n_i_k
    FROM
        citations_with_ipc
    WHERE
        cited_ipc4_code IS NOT NULL
    GROUP BY
        citing_pub_num,
        cited_ipc4_code
),
originality_calc AS (
    SELECT
        n_i.citing_pub_num,
        n_i.n_i,
        SUM( POWER(n_i_k.n_i_k::FLOAT / n_i.n_i, 2) ) AS sum_of_squares
    FROM
        n_i
        JOIN n_i_k ON n_i.citing_pub_num = n_i_k.citing_pub_num
    GROUP BY
        n_i.citing_pub_num, n_i.n_i
),
originality_scores AS (
    SELECT
        citing_pub_num AS "Publication_Number",
        ROUND(1 - sum_of_squares, 4) AS originality
    FROM
        originality_calc
)
SELECT
    "Publication_Number"
FROM
    originality_scores
ORDER BY
    originality DESC NULLS LAST,
    "Publication_Number"
LIMIT 1;