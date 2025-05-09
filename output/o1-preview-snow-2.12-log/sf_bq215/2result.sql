WITH us_b2_2015_2018 AS (
    SELECT t."publication_number", t."citation"
    FROM PATENTS.PATENTS.PUBLICATIONS t
    WHERE t."country_code" = 'US' AND t."kind_code" = 'B2' AND t."grant_date" BETWEEN 20150101 AND 20181231
),
citations AS (
    SELECT
        t."publication_number" AS "citing_publication",
        c.value::VARIANT:"publication_number"::STRING AS "cited_publication_number"
    FROM us_b2_2015_2018 t,
    LATERAL FLATTEN(input => t."citation") c
),
cited_ipcs AS (
    SELECT
        cp."publication_number" AS "cited_publication_number",
        SUBSTR(ipc.value::VARIANT:"code"::STRING, 0, 4) AS "ipc4_code"
    FROM PATENTS.PATENTS.PUBLICATIONS cp,
    LATERAL FLATTEN(input => cp."ipc") ipc
),
citations_with_ipc AS (
    SELECT
        c."citing_publication",
        ci."ipc4_code"
    FROM citations c
    LEFT JOIN cited_ipcs ci ON c."cited_publication_number" = ci."cited_publication_number"
),
ipc_counts AS (
    SELECT
        "citing_publication",
        "ipc4_code",
        COUNT(*) AS "occurrences"
    FROM citations_with_ipc
    WHERE "ipc4_code" IS NOT NULL
    GROUP BY "citing_publication", "ipc4_code"
),
calculations AS (
    SELECT
        "citing_publication",
        SUM("occurrences") AS "total_occurrences",
        SUM("occurrences" * "occurrences") AS "sum_of_squared_occurrences"
        FROM ipc_counts
    GROUP BY "citing_publication"
    HAVING SUM("occurrences") > 0
),
originality AS (
    SELECT
        "citing_publication",
        ROUND(1 - ("sum_of_squared_occurrences"::FLOAT / POWER("total_occurrences", 2)), 4) AS "Originality_Score"
    FROM calculations
)

SELECT "citing_publication" AS "Publication_Number", "Originality_Score"
FROM originality
ORDER BY "Originality_Score" DESC NULLS LAST
LIMIT 1;