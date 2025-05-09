/* Build one unit-length vector per Nature article using weighted GloVe */
WITH
stop_words AS (          -- small manual stop-word list
  SELECT column1 AS word FROM VALUES
    ('the'), ('and'), ('of'), ('to'), ('in'), ('a'), ('for'), ('on')
),

/* 1) Tokenise BODY -> (article , word)   */
tokens AS (
  SELECT  n."id"                     AS art_id,
          LOWER(tok.value)           AS word
  FROM    "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n,
          LATERAL SPLIT_TO_TABLE(
              REGEXP_REPLACE(n."body", '[^A-Za-z ]', ' '), ' '
          ) tok
  WHERE   tok.value IS NOT NULL
    AND   tok.value <> ''
    AND   LOWER(tok.value) NOT IN (SELECT word FROM stop_words)
),

/* 2) Word counts per article (needed for weighting)             */
word_counts AS (
  SELECT  art_id,
          word,
          COUNT(*) AS word_cnt
  FROM    tokens
  GROUP BY art_id, word
),

/* 3) Join corpus frequency & GloVe vector, compute weight       */
word_vectors AS (
  SELECT  wc.art_id,
          gv."vector"                                AS vec,    -- 300-D array
          wc.word_cnt / POWER(wf."frequency", 0.4)   AS scale   -- weight
  FROM    word_counts wc
  JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
       ON wf."word" = wc.word
  JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"    gv
       ON gv."word" = wc.word
),

/* 4) Multiply each component by its weight and sum per article  */
components AS (
  SELECT  wv.art_id,
          f.index                      AS pos,          -- component index 0-299
          SUM( f.value::FLOAT * wv.scale ) AS comp_sum
  FROM    word_vectors wv,
          LATERAL FLATTEN( INPUT => wv.vec ) f
  GROUP BY wv.art_id, f.index
),

/* 5) L2-norm of each raw article vector                        */
norms AS (
  SELECT  art_id,
          SQRT( SUM( comp_sum * comp_sum ) ) AS magnitude
  FROM    components
  GROUP BY art_id
),

/* 6) Normalise to unit length and build ARRAY<300 FLOAT>        */
article_vecs AS (
  SELECT  c.art_id,
          ARRAY_AGG( c.comp_sum / n.magnitude )
              WITHIN GROUP (ORDER BY c.pos)          AS article_vector
  FROM    components c
  JOIN    norms n  ON n.art_id = c.art_id
  GROUP BY c.art_id
),

/* 7) Attach article metadata                                   */
final AS (
  SELECT  av.art_id                 AS "id",
          nt."date",
          nt."title",
          av.article_vector
  FROM    article_vecs av
  JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" nt
       ON nt."id" = av.art_id
)

SELECT  "id",
        "date",
        "title",
        article_vector
FROM    final
ORDER BY "date" NULLS LAST;