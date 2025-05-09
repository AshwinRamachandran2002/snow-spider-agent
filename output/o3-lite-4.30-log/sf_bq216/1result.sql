WITH target_vec AS (   -- vector of the focal patent
    SELECT 
        f.index        AS "idx",
        f.value::FLOAT AS "val"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB t,
         LATERAL FLATTEN(input => t."embedding_v1") f
    WHERE t."publication_number" = 'US-9741766-B2'
), candidate_emb AS (  -- embeddings of all 2016‑filed patents (except the focal one)
    SELECT 
        a."publication_number",
        f.index        AS "idx",
        f.value::FLOAT AS "val"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
      ON a."publication_number" = p."publication_number"
    ,    LATERAL FLATTEN(input => a."embedding_v1") f
    WHERE a."embedding_v1" IS NOT NULL
      AND a."publication_number" <> 'US-9741766-B2'
      AND LEFT(TO_VARCHAR(p."filing_date"), 4) = '2016'
), scores AS (         -- dot‑product similarity
    SELECT 
        c."publication_number",
        SUM(c."val" * t."val") AS "similarity"
    FROM candidate_emb c
    JOIN target_vec  t
      ON c."idx" = t."idx"
    GROUP BY c."publication_number"
)
SELECT "publication_number"
FROM scores
ORDER BY "similarity" DESC NULLS LAST
LIMIT 5;