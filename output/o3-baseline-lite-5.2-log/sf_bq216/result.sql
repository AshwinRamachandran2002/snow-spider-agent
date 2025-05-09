WITH target_flat AS (   -- embedding of the focal patent
    SELECT
        f.index  AS idx,
        f.value::FLOAT AS val
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB t,
         LATERAL FLATTEN (INPUT => t."embedding_v1") f
    WHERE t."publication_number" = 'US-9741766-B2'
),

target_year AS (        -- filing year of the focal patent
    SELECT
        FLOOR(p."filing_date" / 10000) AS filing_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE p."publication_number" = 'US-9741766-B2'
),

candidates AS (         -- patents filed in the same year and with embeddings
    SELECT
        p."publication_number",
        a."embedding_v1" AS emb_vec
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS      p
    JOIN target_year ty
         ON FLOOR(p."filing_date" / 10000) = ty.filing_year
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB       a
         ON a."publication_number" = p."publication_number"
    WHERE p."publication_number" <> 'US-9741766-B2'
),

candidates_flat AS (    -- flatten candidate embeddings
    SELECT
        c."publication_number",
        f.index          AS idx,
        f.value::FLOAT   AS val
    FROM candidates c,
         LATERAL FLATTEN (INPUT => c.emb_vec) f
),

similarity AS (         -- dot‑product similarity with the focal patent
    SELECT
        cf."publication_number",
        SUM(cf.val * tf.val) AS similarity_score
    FROM candidates_flat cf
    JOIN target_flat    tf
         ON cf.idx = tf.idx
    GROUP BY cf."publication_number"
)

SELECT
    "publication_number"
FROM similarity
ORDER BY similarity_score DESC NULLS LAST,
         "publication_number"
LIMIT 5;