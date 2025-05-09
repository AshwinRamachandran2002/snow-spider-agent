/*  Top‑5 patents filed in the same year as US‑9741766‑B2 that are most
    similar to it based on the cosine‑like (dot‑product) similarity of the
    Google‑supplied text‑embeddings                                          */

WITH "REF_PUB" AS (          --  reference patent: embedding & filing year
    SELECT
        ae."embedding_v1"               AS "emb_variant",
        FLOOR(p."filing_date" / 10000)  AS "filing_year"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."ABS_AND_EMB"  ae
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p
      ON ae."publication_number" = p."publication_number"
    WHERE ae."publication_number" = 'US-9741766-B2'
    LIMIT 1
),
"REF_EMB" AS (               --  explode reference embedding into (idx,val)
    SELECT
        f.index     AS "idx",
        f.value::FLOAT  AS "ref_val"
    FROM "REF_PUB",
         LATERAL FLATTEN ( INPUT => "emb_variant" ) f
),
"CANDIDATES" AS (            --  patents filed in the same year, w/ embeddings
    SELECT
        ae."publication_number",
        ae."embedding_v1" AS "emb_variant"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."ABS_AND_EMB"  ae
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p
      ON ae."publication_number" = p."publication_number"
    JOIN "REF_PUB" rp
      ON FLOOR(p."filing_date" / 10000) = rp."filing_year"
    WHERE ae."embedding_v1" IS NOT NULL
      AND ae."publication_number" <> 'US-9741766-B2'
),
"CAND_FLAT" AS (             --  explode each candidate embedding
    SELECT
        c."publication_number",
        f.index          AS "idx",
        f.value::FLOAT   AS "cand_val"
    FROM "CANDIDATES" c,
         LATERAL FLATTEN ( INPUT => c."emb_variant" ) f
),
"SIM" AS (                   --  dot‑product similarity with reference patent
    SELECT
        cf."publication_number",
        SUM(cf."cand_val" * re."ref_val") AS "similarity"
    FROM "CAND_FLAT" cf
    JOIN "REF_EMB"  re
      ON cf."idx" = re."idx"
    GROUP BY cf."publication_number"
)
SELECT
    "publication_number"
FROM "SIM"
ORDER BY "similarity" DESC NULLS LAST,
         "publication_number"
LIMIT 5;