WITH stopwords(word) AS (
    SELECT column1 FROM VALUES
        ('the'),('and'),('for'),('with'),('that'),('this'),
        ('have'),('has'),('are'),('was'),('were'),('but'),
        ('not'),('from'),('into'),('between'),('before'),
        ('after'),('during'),('above'),('below'),('over'),
        ('under'),('again'),('against'),('when'),('where'),
        ('which'),('while'),('will'),('would'),('could'),
        ('should'),('about'),('upon'),('these'),('those'),
        ('been'),('being'),('than'),('then')
),
/*--- pre‑filter articles that mention at least one key term ---*/
filtered_articles AS (
    SELECT "id","date","title","body"
    FROM  "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE"
    WHERE "body" IS NOT NULL
      AND ( "body" ILIKE '%epigenetic%' 
         OR "body" ILIKE '%cerebral%' 
         OR "body" ILIKE '%organoid%' )
),
/*--------------- tokenise & drop stop‑words -------------------*/
article_tokens AS (
    SELECT fa."id",
           fa."date",
           fa."title",
           tok.value::STRING AS token
    FROM   filtered_articles fa,
           LATERAL FLATTEN(
               INPUT => SPLIT(
                   REGEXP_REPLACE(LOWER(fa."body"), '[^a-z ]',' '),
                   ' ')
           ) tok
    WHERE  tok.value::STRING <> ''
       AND LENGTH(tok.value::STRING) > 2
       AND tok.value::STRING NOT IN (SELECT word FROM stopwords)
),
/*---------- attach vectors & re‑weight by 1/freq^0.4 ----------*/
token_vectors AS (
    SELECT at."id",
           at."date",
           at."title",
           gv."vector"                     AS vec,
           wf."frequency"                  AS freq
    FROM   article_tokens at
    JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS" gv
           ON gv."word" = at.token
    JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
           ON wf."word" = at.token
),
weighted_dims AS (
    SELECT tv."id",
           tv."date",
           tv."title",
           f.index                         AS dim,
           f.value::FLOAT / POWER(tv.freq,0.4) AS val
    FROM   token_vectors tv,
           LATERAL FLATTEN(INPUT => tv.vec) f
),
/*---------- sum dimensions & normalise per article -----------*/
summed AS (
    SELECT "id","date","title", dim, SUM(val) AS dim_sum
    FROM   weighted_dims
    GROUP BY "id","date","title", dim
),
norms AS (
    SELECT "id", SQRT(SUM(dim_sum*dim_sum)) AS len
    FROM   summed
    GROUP BY "id"
),
article_vec AS (
    SELECT s."id", s."date", s."title",
           s.dim,
           s.dim_sum / NULLIF(n.len,0)      AS val
    FROM   summed s
    JOIN   norms  n ON n."id" = s."id"
),
/*---------------- build query vector -------------------------*/
query_tokens(token) AS (
    SELECT column1 FROM VALUES
        ('epigenetics'),('cerebral'),('organoids'),
        ('promising'),('directions'),('autism'),
        ('spectrum'),('disorders')
),
query_base AS (
    SELECT gv."vector" AS vec,
           wf."frequency" AS freq
    FROM   query_tokens qt
    JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS" gv
           ON gv."word" = qt.token
    JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
           ON wf."word" = qt.token
),
query_weighted AS (
    SELECT f.index AS dim,
           f.value::FLOAT / POWER(qb.freq,0.4) AS val
    FROM   query_base qb,
           LATERAL FLATTEN(INPUT => qb.vec) f
),
query_sum AS (
    SELECT dim, SUM(val) AS dim_sum
    FROM   query_weighted
    GROUP BY dim
),
query_norm AS (
    SELECT SQRT(SUM(dim_sum*dim_sum)) AS len FROM query_sum
),
query_vec AS (
    SELECT dim,
           dim_sum / (SELECT len FROM query_norm) AS val
    FROM   query_sum
),
/*---------------- cosine similarity --------------------------*/
cosine AS (
    SELECT av."id",
           av."date",
           av."title",
           SUM(av.val * qv.val)             AS cosine_similarity
    FROM   article_vec av
    JOIN   query_vec  qv USING (dim)
    GROUP BY av."id", av."date", av."title"
)
SELECT  "id",
        "date",
        "title",
        ROUND(cosine_similarity,4) AS cosine_similarity
FROM    cosine
ORDER BY cosine_similarity DESC NULLS LAST,
         "date"              DESC NULLS LAST
LIMIT 10;