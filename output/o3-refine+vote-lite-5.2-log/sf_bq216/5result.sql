WITH
/* --- 1.  embedding vector for the reference patent ----------------------- */
target_emb AS (
    SELECT "embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB
    WHERE "publication_number" = 'US-9741766-B2'
    LIMIT 1
),
target_flat AS (               -- one row per vector element
    SELECT
        f.index  AS idx,
        f.value::FLOAT AS val
    FROM target_emb te,
         LATERAL FLATTEN(input => te."embedding_v1") f
),

/* --- 2.  filing year of the reference patent ----------------------------- */
ref_year AS (
    SELECT FLOOR("filing_date" / 10000) AS filing_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
      AND "filing_date" IS NOT NULL
    LIMIT 1
),

/* --- 3.  candidate patents from the same filing year --------------------- */
candidates AS (
    SELECT
        a."publication_number",
        a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB      a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS     p
         ON a."publication_number" = p."publication_number"
    JOIN ref_year r
         ON FLOOR(p."filing_date" / 10000) = r.filing_year
    WHERE a."publication_number" <> 'US-9741766-B2'
      AND a."embedding_v1" IS NOT NULL
      AND p."filing_date" IS NOT NULL
),

/* --- 4.  similarity (dot‑product) calculation --------------------------- */
similarity_scores AS (
    SELECT
        c."publication_number",
        SUM(tf.val * cf.value::FLOAT) AS similarity
    FROM  candidates c,
          LATERAL FLATTEN(input => c."embedding_v1") cf
    JOIN  target_flat tf
          ON tf.idx = cf.index
    GROUP BY c."publication_number"
)

/* --- 5.  top‑5 most similar patents ------------------------------------- */
SELECT "publication_number"
FROM   similarity_scores
ORDER  BY similarity DESC NULLS LAST
LIMIT 5;