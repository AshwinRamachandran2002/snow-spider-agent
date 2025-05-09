/*  Top-5 patents filed in the same year as US-9741766-B2
    that are most similar to it (dot-product of text-embeddings)          */

WITH target AS (           -- filing year & embedding of the focal patent
    SELECT
        CAST(SUBSTR(CAST(p."filing_date" AS STRING),1,4) AS INTEGER)  AS "filing_year",
        a."embedding_v1"                                             AS "t_emb"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS      p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB       a
          ON p."publication_number" = a."publication_number"
    WHERE p."publication_number" = 'US-9741766-B2'
),

target_vec AS (            -- explode focal-patent embedding into index/value
    SELECT
        f.index      AS "idx",
        f.value::FLOAT  AS "t_val"
    FROM target, LATERAL FLATTEN(input => target."t_emb") f
),

candidates AS (            -- all other patents filed in the same year
    SELECT
        p."publication_number",
        a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS      p
    JOIN target t
          ON CAST(SUBSTR(CAST(p."filing_date" AS STRING),1,4) AS INTEGER) = t."filing_year"
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB       a
          ON p."publication_number" = a."publication_number"
    WHERE p."publication_number" <> 'US-9741766-B2'
),

candidate_vecs AS (        -- explode embeddings of candidate patents
    SELECT
        c."publication_number",
        f.index         AS "idx",
        f.value::FLOAT  AS "c_val"
    FROM candidates c, LATERAL FLATTEN(input => c."embedding_v1") f
),

dot_products AS (          -- dot-product similarity
    SELECT
        cv."publication_number",
        SUM(cv."c_val" * tv."t_val")  AS "similarity"
    FROM candidate_vecs  cv
    JOIN target_vec      tv  ON cv."idx" = tv."idx"
    GROUP BY cv."publication_number"
)

SELECT
    "publication_number"
FROM dot_products
ORDER BY "similarity" DESC NULLS LAST
LIMIT 5;