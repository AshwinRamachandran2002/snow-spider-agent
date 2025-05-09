WITH focal AS (
    SELECT 
        a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  a
    WHERE a."publication_number" = 'US-9741766-B2'
), focal_vec AS (
    SELECT 
        fv.index AS idx,
        fv.value::FLOAT AS val
    FROM focal f,
         LATERAL FLATTEN(INPUT => f."embedding_v1") fv
), filing_year AS (
    SELECT 
        SUBSTR(p."filing_date"::STRING,1,4) AS yr
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE p."publication_number" = 'US-9741766-B2'
), candidates AS (
    SELECT 
        a."publication_number",
        a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
          ON a."publication_number" = p."publication_number"
    JOIN filing_year fy
          ON SUBSTR(p."filing_date"::STRING,1,4) = fy.yr
    WHERE a."publication_number" <> 'US-9741766-B2'
), cand_vec AS (
    SELECT 
        c."publication_number",
        cv.index AS idx,
        cv.value::FLOAT AS val
    FROM candidates c,
         LATERAL FLATTEN(INPUT => c."embedding_v1") cv
), similarities AS (
    SELECT 
        c."publication_number",
        SUM(f.val * c.val) AS similarity_score
    FROM focal_vec f
    JOIN cand_vec c
      ON f.idx = c.idx
    GROUP BY c."publication_number"
)
SELECT 
    "publication_number"
FROM similarities
ORDER BY similarity_score DESC NULLS LAST
LIMIT 5;