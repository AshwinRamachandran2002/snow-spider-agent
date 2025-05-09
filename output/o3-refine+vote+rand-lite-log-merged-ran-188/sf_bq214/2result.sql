/* -----------------------------------------------------------
   Corrected version – uses quoted identifier "top_emb"
----------------------------------------------------------- */
WITH
-----------------------------------------------------------------
us_b2_2010_14 AS (   -- B2 utility patents granted 2010-2014
    SELECT  p."publication_number",
            p."filing_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE   p."country_code" = 'US'
      AND   p."kind_code"    = 'B2'
      AND   p."grant_date"  BETWEEN 20100101 AND 20141231
      AND   p."filing_date"  > 0
),
-----------------------------------------------------------------
forward_30d_counts AS (   -- count forward citations within 30 days
    SELECT  tgt."publication_number",
            tgt."filing_date",
            COUNT(*) AS "fwd_cites_30d"
    FROM    us_b2_2010_14 tgt
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cit
           ON  cit."filing_date"
                BETWEEN tgt."filing_date" AND tgt."filing_date" + 30
    ,       LATERAL FLATTEN(input => cit."citation") c
    WHERE   c.value:"publication_number"::STRING = tgt."publication_number"
    GROUP BY tgt."publication_number", tgt."filing_date"
),
-----------------------------------------------------------------
top_patent AS (       -- single most-cited patent
    SELECT  *
    FROM    forward_30d_counts
    ORDER BY "fwd_cites_30d" DESC NULLS LAST
    LIMIT   1
),
-----------------------------------------------------------------
top_embedding AS (
    SELECT  t."publication_number"               AS "top_pub",
            t."filing_date",
            t."fwd_cites_30d",
            FLOOR(t."filing_date"/10000)         AS "filing_year",
            e."embedding_v1"                     AS "top_emb"
    FROM    top_patent t
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB e
           ON e."publication_number" = t."publication_number"
    WHERE   e."embedding_v1" IS NOT NULL
),
-----------------------------------------------------------------
same_year_embeddings AS (   -- other patents in same filing year
    SELECT  p."publication_number",
            e."embedding_v1" AS "cand_emb"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  e
           ON e."publication_number" = p."publication_number"
    JOIN    top_embedding t
           ON FLOOR(p."filing_date"/10000) = t."filing_year"
    WHERE   p."publication_number" <> t."top_pub"
      AND   e."embedding_v1" IS NOT NULL
),
-----------------------------------------------------------------
top_vec AS (          -- unnest vector of top patent
    SELECT  pos.index        AS "idx",
            pos.value::FLOAT AS "top_val"
    FROM    top_embedding,
            LATERAL FLATTEN(input => "top_emb") pos
),
-----------------------------------------------------------------
similarity_scores AS (   -- dot-product similarity
    SELECT  c."publication_number" AS "similar_pub",
            SUM(tv."top_val" * cv.value::FLOAT) AS "similarity"
    FROM    same_year_embeddings c
    ,       LATERAL FLATTEN(input => c."cand_emb") cv
    JOIN    top_vec tv
           ON cv.index = tv."idx"
    GROUP BY c."publication_number"
),
-----------------------------------------------------------------
best_match AS (       -- highest-similarity patent
    SELECT  *
    FROM    similarity_scores
    ORDER BY "similarity" DESC NULLS LAST
    LIMIT   1
)
-----------------------------------------------------------------
SELECT  t."top_pub"           AS "top_publication_number",
        t."filing_date"       AS "top_filing_date",
        t."fwd_cites_30d"     AS "forward_cites_30d",
        b."similar_pub"       AS "most_similar_pub",
        b."similarity"        AS "dot_product_similarity"
FROM    top_embedding t
JOIN    best_match    b  ON 1 = 1;