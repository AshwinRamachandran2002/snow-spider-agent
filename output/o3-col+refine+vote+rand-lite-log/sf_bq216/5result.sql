WITH focal AS (  -- filing year of the target patent
    SELECT FLOOR("filing_date"/10000) AS "filing_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
),
target_vec AS (  -- flattened embedding of the target patent
    SELECT fl.index AS idx,
           fl.value::FLOAT AS t_val
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB, 
         LATERAL FLATTEN(input => "embedding_v1") fl
    WHERE "publication_number" = 'US-9741766-B2'
),
candidates AS (  -- compute similarity for all 2016-filed patents (excluding the target)
    SELECT p."publication_number",
           SUM(cv.value::FLOAT * tv.t_val) AS similarity
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS      p
    JOIN focal f
      ON FLOOR(p."filing_date"/10000) = f."filing_year"
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB       e
      ON p."publication_number" = e."publication_number",
         LATERAL FLATTEN(input => e."embedding_v1")      cv
    JOIN target_vec                                      tv
      ON cv.index = tv.idx
    WHERE p."publication_number" <> 'US-9741766-B2'
    GROUP BY p."publication_number"
)
SELECT "publication_number"
FROM   candidates
ORDER BY similarity DESC NULLS LAST
LIMIT 5;