/*  Top-5 patents (same filing year as US-9741766-B2) with highest
    text-embedding similarity to US-9741766-B2                       */

WITH ref_year AS (  -- filing year of the reference patent
    SELECT SUBSTR("filing_date"::STRING,1,4) AS "filing_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
    LIMIT 1
),
ref_embed AS (       -- embedding elements of the reference patent
    SELECT  
           f_ref."INDEX"      AS idx ,
           f_ref."VALUE"::FLOAT AS val
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  r,
         LATERAL FLATTEN(INPUT => r."embedding_v1") f_ref
    WHERE r."publication_number" = 'US-9741766-B2'
),
candidates AS (      -- patents filed in the same year that also have embeddings
    SELECT p."publication_number"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS      p
    JOIN ref_year y
      ON SUBSTR(p."filing_date"::STRING,1,4) = y."filing_year"
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB       a
      ON a."publication_number" = p."publication_number"
),
similarity AS (      -- dot-product similarity for every candidate
    SELECT  
           c."publication_number",
           SUM( f_c."VALUE"::FLOAT * r.val ) AS dot_product_sim
    FROM candidates                                     c
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB      emb
      ON emb."publication_number" = c."publication_number"
         , LATERAL FLATTEN(INPUT => emb."embedding_v1") f_c
    JOIN ref_embed                                      r
      ON r.idx = f_c."INDEX"
    GROUP BY c."publication_number"
)
SELECT "publication_number"
FROM   similarity
ORDER BY dot_product_sim DESC NULLS LAST
LIMIT 5;