WITH tgt AS (               -- target patent: vector + filing year
    SELECT 
        a."embedding_v1"                    AS "tgt_emb",
        FLOOR(p."filing_date"/10000)        AS "tgt_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS   p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB    a
          ON p."publication_number" = a."publication_number"
    WHERE p."publication_number" = 'US-9741766-B2'
),                                                             -- candidates: same filing-year, have embeddings, exclude target
cands AS (
    SELECT 
        a."publication_number",
        a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
          ON a."publication_number" = p."publication_number"
    JOIN tgt t
          ON FLOOR(p."filing_date"/10000) = t."tgt_year"
    WHERE a."publication_number" <> 'US-9741766-B2'
),                                                             -- flatten candidate vectors
cand_flat AS (
    SELECT 
        c."publication_number",
        cf."INDEX"                    AS "idx",
        cf."VALUE"::FLOAT             AS "cval"
    FROM cands c,
         LATERAL FLATTEN(input => c."embedding_v1") cf
),                                                             -- flatten target vector
tgt_flat AS (
    SELECT 
        tf."INDEX"            AS "idx",
        tf."VALUE"::FLOAT     AS "tval"
    FROM tgt,
         LATERAL FLATTEN(input => tgt."tgt_emb") tf
),                                                             -- dot-product similarities
sims AS (
    SELECT
        cf."publication_number",
        SUM(cf."cval" * tf."tval")  AS "similarity"
    FROM cand_flat cf
    JOIN tgt_flat  tf
          ON cf."idx" = tf."idx"
    GROUP BY cf."publication_number"
)
SELECT 
    "publication_number"
FROM sims
ORDER BY "similarity" DESC NULLS LAST
LIMIT 5;