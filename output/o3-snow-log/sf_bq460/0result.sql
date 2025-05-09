WITH
/* --------------------------------------------------------
   1) stop-word list
---------------------------------------------------------*/
stopwords(word) AS (
  SELECT column1 FROM VALUES
    ('a'),('an'),('the'),('and'),('or'),('but'),('if'),('while'),('with'),('for'),
    ('on'),('in'),('to'),('of'),('by'),('is'),('are'),('was'),('were'),
    ('be'),('been'),('has'),('have'),('had'),('do'),('does'),('did'),
    ('that'),('this'),('these'),('those'),('i'),('you'),('he'),('she'),
    ('it'),('we'),('they'),('them'),('as'),('at'),('from'),('which'),
    ('who'),('whom'),('not'),('can'),('could'),('should'),('would'),
    ('may'),('might'),('will'),('shall')
),

/* --------------------------------------------------------
   2) tokenise bodies, lower-case, strip punctuation
---------------------------------------------------------*/
tokens AS (
  SELECT  n."id"                                                AS article_id,
          LOWER(TRIM(tok.value))                                AS word
  FROM    WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
          LATERAL SPLIT_TO_TABLE(
              REGEXP_REPLACE(n."body", '[^A-Za-z0-9 ]', ' '),   -- keep letters/digits/space
              ' '
          ) tok
  WHERE   tok.value IS NOT NULL
          AND tok.value <> ''
),

/* --------------------------------------------------------
   3) remove stop-words, very short tokens
---------------------------------------------------------*/
tokens_filtered AS (
  SELECT  t.article_id,
          t.word
  FROM    tokens t
  LEFT  JOIN stopwords s
         ON t.word = s.word
  WHERE   s.word IS NULL
          AND LENGTH(t.word) > 2
),

/* --------------------------------------------------------
   4) count occurrences of every word in each article
---------------------------------------------------------*/
token_counts AS (
  SELECT  article_id,
          word,
          COUNT(*) AS cnt
  FROM    tokens_filtered
  GROUP  BY article_id, word
),

/* --------------------------------------------------------
   5) join word-frequency + GloVe vectors, flatten ONCE
---------------------------------------------------------*/
article_dim_values AS (
  SELECT   tc.article_id,
           f.index                               AS dim,
           SUM( (f.value::FLOAT) * tc.cnt
                / POWER(wf."frequency", 0.4) )   AS dim_sum
  FROM      token_counts                      tc
  JOIN      WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = tc.word
  JOIN      WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS   gv
         ON gv."word" = tc.word
  ,         LATERAL FLATTEN(INPUT => gv."vector")           f   -- 300 dims
  GROUP BY  tc.article_id, f.index
),

/* --------------------------------------------------------
   6) vector norm for each article
---------------------------------------------------------*/
vector_norm AS (
  SELECT  article_id,
          SQRT(SUM(POWER(dim_sum,2))) AS norm
  FROM    article_dim_values
  GROUP BY article_id
  HAVING  norm > 0
),

/* --------------------------------------------------------
   7) normalise vectors (unit length)
---------------------------------------------------------*/
normalized AS (
  SELECT  adv.article_id,
          adv.dim,
          adv.dim_sum / vn.norm AS value
  FROM    article_dim_values adv
  JOIN    vector_norm        vn
     ON   adv.article_id = vn.article_id
),

/* --------------------------------------------------------
   8) target article normalised vector
---------------------------------------------------------*/
target_vec AS (
  SELECT dim, value
  FROM   normalized
  WHERE  article_id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),

/* --------------------------------------------------------
   9) cosine similarity (dot product of unit vectors)
---------------------------------------------------------*/
similarity AS (
  SELECT  n.article_id,
          SUM(n.value * tv.value) AS cosine_sim
  FROM    normalized n
  JOIN    target_vec tv
    ON    n.dim = tv.dim
  GROUP BY n.article_id
)

/* --------------------------------------------------------
   10) return top-10 similar articles (exclude target)
---------------------------------------------------------*/
SELECT  sim.article_id                        AS "ID",
        nat."date"                            AS "DATE",
        nat."title"                           AS "TITLE",
        sim.cosine_sim                        AS "COSINE_SIMILARITY"
FROM    similarity sim
JOIN    WORD_VECTORS_US.WORD_VECTORS_US.NATURE nat
   ON   sim.article_id = nat."id"
WHERE   sim.article_id <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
ORDER  BY sim.cosine_sim DESC NULLS LAST
LIMIT 10;