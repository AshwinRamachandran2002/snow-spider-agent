WITH citing_patents AS (
    SELECT
        t."publication_number" AS citing_publication_number,
        c.value::VARIANT:"publication_number"::STRING AS cited_publication_number
    FROM
        PATENTS.PATENTS.PUBLICATIONS t,
        LATERAL FLATTEN(input => t."citation") c
    WHERE
        t."country_code" = 'US'
        AND t."kind_code" = 'B2'
        AND t."grant_date" BETWEEN 20150101 AND 20181231
),
cited_ipc_codes AS (
    SELECT
        p."publication_number" AS cited_publication_number,
        SUBSTR(ipc_item.value::VARIANT:"code"::STRING, 1, 4) AS ipc_4
    FROM
        PATENTS.PATENTS.PUBLICATIONS p,
        LATERAL FLATTEN(input => p."ipc") ipc_item
),
ipc_counts AS (
    SELECT
        cp.citing_publication_number,
        cic.ipc_4,
        COUNT(*) AS ipc_count
    FROM
        citing_patents cp
    LEFT JOIN cited_ipc_codes cic
        ON cp.cited_publication_number = cic.cited_publication_number
    WHERE
        cic.ipc_4 IS NOT NULL
    GROUP BY
        cp.citing_publication_number,
        cic.ipc_4
),
total_citations AS (
    SELECT
        cp.citing_publication_number,
        COUNT(*) AS total_citation_count
    FROM
        citing_patents cp
    GROUP BY
        cp.citing_publication_number
),
originality_scores AS (
    SELECT
        ic.citing_publication_number,
        ROUND(1 - SUM(POWER(ic.ipc_count::FLOAT / tc.total_citation_count, 2)), 4) AS originality
    FROM
        ipc_counts ic
    JOIN total_citations tc
        ON ic.citing_publication_number = tc.citing_publication_number
    GROUP BY
        ic.citing_publication_number
)
SELECT
    os.citing_publication_number AS "Publication_Number"
FROM
    originality_scores os
ORDER BY
    os.originality DESC NULLS LAST
LIMIT 1;