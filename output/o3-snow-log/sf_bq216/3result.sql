WITH target AS (   /* embedding + filing year of focal patent */
    SELECT
        a."embedding_v1"           AS emb_target ,
        FLOOR( p."filing_date" / 10000 )  AS filing_year          -- YYYYMMDD → YYYY
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
          ON p."publication_number" = a."publication_number"
    WHERE a."publication_number" = 'US-9741766-B2'
      AND p."filing_date" > 0
),
/* explode target embedding */
target_vec AS (
    SELECT 
        f.index       AS idx ,
        f.value::FLOAT AS val
    FROM target ,
         LATERAL FLATTEN( INPUT => target.emb_target ) f
),
/* candidate patents: same filing year, have embeddings, exclude focal */
candidates AS (
    SELECT
        a."publication_number" ,
        a."embedding_v1"        AS emb_candidate
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
          ON p."publication_number" = a."publication_number"
    JOIN target t
          ON FLOOR( p."filing_date" / 10000 ) = t.filing_year
    WHERE a."embedding_v1" IS NOT NULL
      AND p."filing_date" > 0
      AND a."publication_number" <> 'US-9741766-B2'
),
/* explode candidate embeddings */
candidate_vecs AS (
    SELECT
        c."publication_number" ,
        f.index      AS idx ,
        f.value::FLOAT AS val
    FROM candidates c ,
         LATERAL FLATTEN( INPUT => c.emb_candidate ) f
)
/* similarity (dot-product) & top-5 */
SELECT
    cv."publication_number"
FROM candidate_vecs cv
JOIN target_vec     tv
  ON cv.idx = tv.idx
GROUP BY
    cv."publication_number"
ORDER BY
    SUM( cv.val * tv.val ) DESC NULLS LAST
LIMIT 5;