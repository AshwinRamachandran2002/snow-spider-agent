WITH target_embedding AS (
    SELECT f.seq, f.value::FLOAT AS target_value
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    CROSS JOIN LATERAL FLATTEN(input => PARSE_JSON(a."embedding_v1")) f
    WHERE a."publication_number" = 'US-9741766-B2'
),
filing_year AS (
    SELECT SUBSTRING(TO_VARCHAR("filing_date"), 1, 4) AS "year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
),
filings_in_year AS (
    SELECT p."publication_number", a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
        ON p."publication_number" = a."publication_number"
    WHERE SUBSTRING(TO_VARCHAR(p."filing_date"), 1, 4) = (SELECT "year" FROM filing_year)
      AND p."publication_number" != 'US-9741766-B2'
      AND a."embedding_v1" IS NOT NULL
),
flattened_embeddings AS (
    SELECT fe."publication_number", f.seq, f.value::FLOAT AS value
    FROM filings_in_year fe
    CROSS JOIN LATERAL FLATTEN(input => PARSE_JSON(fe."embedding_v1")) f
),
dot_products AS (
    SELECT fe."publication_number", SUM(ROUND(te.target_value * fe.value, 4)) AS dot_product
    FROM flattened_embeddings fe
    JOIN target_embedding te ON fe.seq = te.seq
    GROUP BY fe."publication_number"
),
top5 AS (
    SELECT "publication_number"
    FROM dot_products
    ORDER BY dot_product DESC NULLS LAST
    LIMIT 5
)
SELECT "publication_number"
FROM top5;