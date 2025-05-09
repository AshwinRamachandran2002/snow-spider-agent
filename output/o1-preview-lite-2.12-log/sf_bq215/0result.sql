SELECT
    "publication_number",
    "originality_score"
FROM
    (
        WITH t AS (
            SELECT
                "publication_number"
            FROM
                PATENTS.PATENTS.PUBLICATIONS
            WHERE
                "kind_code" = 'B2'
                AND "grant_date" BETWEEN 20150101 AND 20181231
                AND "publication_number" LIKE 'US-%'
        ),
        nk_table AS (
            SELECT
                t."publication_number" AS "publication_number",
                SUBSTR(ipc_cited.value::VARIANT:"code"::STRING, 1, 4) AS "ipc4_code",
                COUNT(*) AS "n_k"
            FROM
                t
                JOIN PATENTS.PATENTS.PUBLICATIONS t_pub ON t_pub."publication_number" = t."publication_number"
                CROSS JOIN LATERAL FLATTEN(input => t_pub."citation") c
                LEFT JOIN PATENTS.PATENTS.PUBLICATIONS p
                    ON p."publication_number" = c.value::VARIANT:"publication_number"::STRING
                LEFT JOIN LATERAL FLATTEN(input => p."ipc") ipc_cited
            WHERE
                ipc_cited.value::VARIANT:"code"::STRING IS NOT NULL
            GROUP BY
                t."publication_number",
                SUBSTR(ipc_cited.value::VARIANT:"code"::STRING, 1, 4)
        ),
        nk_sums AS (
            SELECT
                "publication_number",
                SUM(POWER("n_k", 2)) AS "sum_nk_squared",
                SUM("n_k") AS "sum_nk"
            FROM
                nk_table
            GROUP BY
                "publication_number"
        ),
        originality_scores AS (
            SELECT
                t."publication_number",
                CASE WHEN nk_sums."sum_nk" IS NOT NULL AND nk_sums."sum_nk" <> 0
                    THEN ROUND(1 - (nk_sums."sum_nk_squared" / POWER(nk_sums."sum_nk", 2)), 4)
                    ELSE 0
                END AS "originality_score"
            FROM
                t
                LEFT JOIN nk_sums ON t."publication_number" = nk_sums."publication_number"
        )
        SELECT
            "publication_number",
            "originality_score"
        FROM
            originality_scores
        ORDER BY
            "originality_score" DESC NULLS LAST
        LIMIT 1
    );