WITH focal_year AS (                -- filing year of the focal patent
    SELECT FLOOR("filing_date"/10000) AS yr
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
),
focal_vec AS (                       -- explode focal-patent embedding
    SELECT  fl.seq  AS idx,
            fl.value::FLOAT AS coord
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB fe,
         LATERAL FLATTEN(input => fe."embedding_v1") fl
    WHERE fe."publication_number" = 'US-9741766-B2'
),
peer_vecs AS (                       -- explode embeddings of same-year peers
    SELECT  a."publication_number",
            fl.seq  AS idx,
            fl.value::FLOAT AS coord
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS   p
    JOIN focal_year fy
      ON FLOOR(p."filing_date"/10000) = fy.yr
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB    a
      ON a."publication_number" = p."publication_number"
    ,    LATERAL FLATTEN(input => a."embedding_v1") fl
    WHERE a."publication_number" <> 'US-9741766-B2'          -- exclude focal
)
SELECT  pv."publication_number"
FROM    peer_vecs pv
JOIN    focal_vec fv
  ON    pv.idx = fv.idx                                      -- align dimensions
GROUP BY pv."publication_number"
ORDER BY SUM(pv.coord * fv.coord) DESC NULLS LAST            -- dot-product
LIMIT 5;