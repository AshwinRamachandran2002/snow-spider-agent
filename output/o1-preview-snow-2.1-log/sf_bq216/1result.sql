WITH us_patent_embedding AS (
    SELECT
        f.seq AS idx,
        f.value::FLOAT AS us_value
    FROM 
        PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a,
        LATERAL FLATTEN(INPUT => PARSE_JSON(a."embedding_v1")) f
    WHERE 
        a."publication_number" = 'US-9741766-B2'
),
patents_same_year_embeddings AS (
    SELECT 
        a."publication_number",
        f.seq AS idx,
        f.value::FLOAT AS other_value
    FROM 
        PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
      ON a."publication_number" = p."publication_number",
    LATERAL FLATTEN(INPUT => PARSE_JSON(a."embedding_v1")) f
    WHERE 
        FLOOR(p."filing_date" / 10000) = (
            SELECT FLOOR(p2."filing_date" / 10000)
            FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
            WHERE p2."publication_number" = 'US-9741766-B2'
        )
        AND a."publication_number" != 'US-9741766-B2'
        AND a."embedding_v1" IS NOT NULL
)
SELECT
    p."publication_number"
FROM
    us_patent_embedding u
JOIN
    patents_same_year_embeddings p
    ON u.idx = p.idx
GROUP BY
    p."publication_number"
ORDER BY
    SUM(ROUND(u.us_value * p.other_value, 4)) DESC NULLS LAST
LIMIT 5;