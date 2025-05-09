WITH target AS (   -- embedding vector of the reference patent
    SELECT "embedding_v1" AS emb
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."ABS_AND_EMB"
    WHERE "publication_number" = 'US-9741766-B2'
),
target_flat AS (   -- flatten the reference embedding into (index , value)
    SELECT 
        f.index  AS idx,
        f.value::FLOAT AS val
    FROM target,
         LATERAL FLATTEN(input => target.emb) f
),
ref_year AS (      -- filing year of the reference patent
    SELECT FLOOR("filing_date" / 10000) AS filing_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS"
    WHERE "publication_number" = 'US-9741766-B2'
),
candidates AS (    -- patents filed in the same year with available embeddings
    SELECT
        ae."publication_number",
        ae."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."ABS_AND_EMB"  ae
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p
      ON ae."publication_number" = p."publication_number",
         ref_year
    WHERE FLOOR(p."filing_date" / 10000) = ref_year.filing_year
      AND ae."publication_number" <> 'US-9741766-B2'
      AND ae."embedding_v1" IS NOT NULL
)

SELECT
    c."publication_number"
FROM
    candidates c
    CROSS JOIN LATERAL FLATTEN(input => c."embedding_v1") cf      -- flatten candidate embedding
    JOIN target_flat tf
      ON tf.idx = cf.index                                        -- match vector positions
GROUP BY
    c."publication_number"
ORDER BY
    SUM(tf.val * cf.value::FLOAT) DESC NULLS LAST,                -- dot‑product similarity
    c."publication_number"
LIMIT 5;