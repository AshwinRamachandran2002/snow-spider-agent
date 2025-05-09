WITH focal_patent AS (
    SELECT
        p."publication_number" AS "focal_pub_num",
        p."filing_date" AS "focal_filing_date",
        p."publication_date" AS "focal_publication_date",
        COUNT(DISTINCT pc."publication_number") AS "forward_citations_within_month"
    FROM
        PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
        JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
            ON p."publication_number" = a."publication_number",
        LATERAL FLATTEN(input => a."cited_by") f
        INNER JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pc
            ON pc."publication_number" = f.value::VARIANT:"publication_number"::STRING
    WHERE
        p."country_code" = 'US'
        AND p."kind_code" = 'B2'
        AND p."publication_date" BETWEEN 20100101 AND 20141231
        AND p."filing_date" IS NOT NULL
        AND pc."filing_date" IS NOT NULL
        AND TRY_TO_DATE(TO_VARCHAR(p."filing_date"), 'YYYYMMDD') IS NOT NULL
        AND TRY_TO_DATE(TO_VARCHAR(pc."filing_date"), 'YYYYMMDD') IS NOT NULL
        AND DATEDIFF(
            'day',
            TRY_TO_DATE(TO_VARCHAR(p."filing_date"), 'YYYYMMDD'),
            TRY_TO_DATE(TO_VARCHAR(pc."filing_date"), 'YYYYMMDD')
        ) BETWEEN 0 AND 30
    GROUP BY
        p."publication_number",
        p."filing_date",
        p."publication_date"
    ORDER BY
        "forward_citations_within_month" DESC NULLS LAST
    LIMIT 1
),
focal_embedding AS (
    SELECT
        a."embedding_v1" AS "focal_embedding",
        fp."focal_pub_num",
        fp."focal_filing_date",
        fp."focal_publication_date",
        SUBSTR(TO_VARCHAR(fp."focal_filing_date"), 1, 4) AS "focal_filing_year"
    FROM
        focal_patent fp
        JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
            ON fp."focal_pub_num" = a."publication_number"
),
focal_embedding_elements AS (
    SELECT
        fe.seq AS idx,
        fe.value::FLOAT AS "focal_embedding_value"
    FROM
        focal_embedding f,
        LATERAL FLATTEN(input => f."focal_embedding") fe
),
other_patents AS (
    SELECT
        p."publication_number" AS "other_pub_num",
        p."filing_date" AS "other_filing_date",
        a."embedding_v1" AS "other_embedding"
    FROM
        PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
        JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
            ON p."publication_number" = a."publication_number"
    WHERE
        p."publication_number" != (SELECT "focal_pub_num" FROM focal_embedding)
        AND p."filing_date" IS NOT NULL
        AND TRY_TO_DATE(TO_VARCHAR(p."filing_date"), 'YYYYMMDD') IS NOT NULL
        AND SUBSTR(TO_VARCHAR(p."filing_date"), 1, 4) = (SELECT "focal_filing_year" FROM focal_embedding)
        AND a."embedding_v1" IS NOT NULL
),
other_embedding_elements AS (
    SELECT
        op."other_pub_num",
        oe.seq AS idx,
        oe.value::FLOAT AS "other_embedding_value"
    FROM
        other_patents op,
        LATERAL FLATTEN(input => op."other_embedding") oe
)
SELECT
    (SELECT "focal_pub_num" FROM focal_embedding) AS publication_number,
    oee."other_pub_num" AS most_similar_publication_number,
    ROUND(SUM(fee."focal_embedding_value" * oee."other_embedding_value"), 4) AS similarity
FROM
    focal_embedding_elements fee
    JOIN other_embedding_elements oee
        ON fee.idx = oee.idx
GROUP BY
    oee."other_pub_num"
ORDER BY
    similarity DESC NULLS LAST
LIMIT 1;