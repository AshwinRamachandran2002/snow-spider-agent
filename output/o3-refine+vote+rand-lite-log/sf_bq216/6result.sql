WITH focal_pub AS (
    SELECT "publication_number", "embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB
    WHERE "publication_number" = 'US-9741766-B2'
),
focal_vec AS (
    -- turn the focal embedding into (index , value) rows
    SELECT 
        f_flat.index        AS idx,
        f_flat.value::FLOAT AS val
    FROM focal_pub,
         LATERAL FLATTEN ( INPUT => focal_pub."embedding_v1" ) f_flat
),
focal_year AS (
    SELECT FLOOR("filing_date" / 10000) AS yr
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
),
candidates AS (
    -- all publications filed in the same year and with embeddings
    SELECT a."publication_number",
           a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB      a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS     p
           ON p."publication_number" = a."publication_number"
    JOIN focal_year fy
           ON FLOOR(p."filing_date" / 10000) = fy.yr
    WHERE a."embedding_v1" IS NOT NULL
      AND a."publication_number" <> 'US-9741766-B2'
),
candidate_vecs AS (
    -- explode each candidate embedding
    SELECT 
        c."publication_number",
        c_flat.index        AS idx,
        c_flat.value::FLOAT AS val
    FROM candidates c,
         LATERAL FLATTEN ( INPUT => c."embedding_v1" ) c_flat
)
-- compute dot‑product similarity and pick top 5
SELECT 
    cv."publication_number"
FROM candidate_vecs  cv
JOIN focal_vec       fv
      ON cv.idx = fv.idx
GROUP BY cv."publication_number"
ORDER BY SUM(cv.val * fv.val) DESC NULLS LAST
LIMIT 5;