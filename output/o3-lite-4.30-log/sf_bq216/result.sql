WITH focal_info AS (                                             -- filing year & embedding of US‑9741766‑B2
    SELECT FLOOR(p."filing_date" / 10000)          AS yr,
           e."embedding_v1"                        AS focal_vec
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB   e
           ON p."publication_number" = e."publication_number"
    WHERE  p."publication_number" = 'US-9741766-B2'
), 
focal_emb AS (                                                   -- flatten focal embedding
    SELECT f.index                    AS idx,
           f.value::FLOAT             AS f_val
    FROM   focal_info,
           LATERAL FLATTEN (input => focal_vec) f
), 
focal_norm AS (                                                  -- Euclidean norm of focal vector
    SELECT SQRT(SUM(POWER(f_val, 2))) AS f_norm
    FROM   focal_emb
), 
peer_emb AS (                                                    -- flatten embeddings of same‑year peers
    SELECT p."publication_number",
           fv.index                    AS idx,
           fv.value::FLOAT             AS p_val
    FROM   focal_info fi
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
           ON FLOOR(p."filing_date" / 10000) = fi.yr
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB   e
           ON e."publication_number" = p."publication_number"
         , LATERAL FLATTEN (input => e."embedding_v1") fv
    WHERE  p."publication_number" <> 'US-9741766-B2'
), 
similarity AS (                                                  -- dot product & peer norms
    SELECT pe."publication_number",
           SUM(fe.f_val * pe.p_val)        AS dot_prod,
           SUM(POWER(pe.p_val, 2))         AS p_sq_sum
    FROM   peer_emb  pe
    JOIN   focal_emb fe ON fe.idx = pe.idx
    GROUP BY pe."publication_number"
)
SELECT s."publication_number"                                   -- top‑5 most similar peers
FROM   similarity s
CROSS  JOIN focal_norm fn
ORDER  BY s.dot_prod / (fn.f_norm * SQRT(s.p_sq_sum)) DESC NULLS LAST,
          s."publication_number" ASC
LIMIT 5;