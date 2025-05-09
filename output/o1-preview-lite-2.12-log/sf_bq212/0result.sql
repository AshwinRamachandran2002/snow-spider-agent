WITH code_counts AS (
    SELECT
        SUBSTRING(ipc_u2.value::VARIANT:"code"::STRING, 1, 4) AS "ipc4_code",
        COUNT(*) AS "code_count"
    FROM
        PATENTS.PATENTS.PUBLICATIONS t2,
        LATERAL FLATTEN(input => t2."ipc") ipc_u2
    WHERE
        t2."country_code" = 'US'
        AND t2."kind_code" = 'B2'
        AND t2."grant_date" BETWEEN 20220601 AND 20220930
    GROUP BY
        "ipc4_code"
    HAVING
        COUNT(*) >= 10
),
ipc_codes AS (
    SELECT
        t."publication_number",
        SUBSTRING(ipc_u.value::VARIANT:"code"::STRING, 1, 4) AS "ipc4_code"
    FROM
        PATENTS.PATENTS.PUBLICATIONS t,
        LATERAL FLATTEN(input => t."ipc") ipc_u
    WHERE
        t."country_code" = 'US'
        AND t."kind_code" = 'B2'
        AND t."grant_date" BETWEEN 20220601 AND 20220930
),
ranked_ipc AS (
    SELECT
        ic."publication_number",
        ic."ipc4_code",
        DENSE_RANK() OVER (
            PARTITION BY ic."publication_number"
            ORDER BY cc."code_count" DESC NULLS LAST
        ) AS "rank"
    FROM
        ipc_codes ic
    INNER JOIN
        code_counts cc ON ic."ipc4_code" = cc."ipc4_code"
)
SELECT
    "publication_number",
    "ipc4_code" AS "ipc4"
FROM
    ranked_ipc
WHERE
    "rank" = 1