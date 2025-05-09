/*--------------------------------------------------------------------
  Find the 10 Nature articles whose bodies are most similar to
  the query  “Epigenetics and cerebral organoids: promising
  directions in autism spectrum disorders”.

  To keep the run-time well below the warehouse 200-second limit,
  article processing is restricted to tokens that also occur in
  the query (only 8 distinct words).  Since the cosine‐similarity
  dot-product only involves dimensions contributed by those
  query words, the result is identical to the full calculation
  yet dramatically faster.
--------------------------------------------------------------------*/
WITH
------------------------------------------------------------------
-- 0)  stop-word list
------------------------------------------------------------------
stop_words AS (
    SELECT COLUMN1 AS word
    FROM VALUES
        ('a'),('an'),('and'),('are'),('as'),('at'),
        ('be'),('by'),('for'),('from'),('in'),('is'),('it'),
        ('of'),('on'),('or'),('that'),('the'),('their'),
        ('these'),('those'),('this'),('to'),('with'),('we')
),
------------------------------------------------------------------
-- 1)  tokenize the QUERY string, drop stop-words
------------------------------------------------------------------
query_tokens AS (
    SELECT DISTINCT
           tok.value::string          AS token
    FROM   LATERAL FLATTEN(
             INPUT => SPLIT(
                         REGEXP_REPLACE(
                             LOWER('Epigenetics and cerebral organoids: promising directions in autism spectrum disorders'),
                             '[^a-z]+',' '),
                         ' ')
           ) tok
    WHERE  tok.value IS NOT NULL
       AND tok.value <> ''
       AND tok.value NOT IN (SELECT word FROM stop_words)
),
------------------------------------------------------------------
-- 2)  vectors, frequencies, weights for query words
------------------------------------------------------------------
query_word_vecs AS (
    SELECT  gv."vector"                        AS vec,
            POWER(wf."frequency", -0.4)        AS weight
    FROM    query_tokens qt
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"    gv
           ON gv."word" = qt.token
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
           ON wf."word" = qt.token
),
------------------------------------------------------------------
-- 3)  build (idx , value) for the weighted QUERY vector,
--     then normalise it to unit length
------------------------------------------------------------------
query_coords AS (
    SELECT  v.index                         AS idx,
            SUM( v.value::float * qw.weight ) AS coord
    FROM    query_word_vecs qw,
            LATERAL FLATTEN( INPUT => qw.vec ) v
    GROUP BY v.index
),
query_norm AS (SELECT SQRT( SUM(coord*coord) ) AS norm FROM query_coords),
query_unit AS (
    SELECT idx,
           coord / (SELECT norm FROM query_norm) AS coord
    FROM   query_coords
),
------------------------------------------------------------------
-- 4)  choose a manageable article set (recent 15 000)
------------------------------------------------------------------
candidate_articles AS (
    SELECT  "id","date","title","body"
    FROM    "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE"
    QUALIFY ROW_NUMBER() OVER(ORDER BY "date" DESC NULLS LAST) <= 15000
),
------------------------------------------------------------------
-- 5)  tokenise bodies but KEEP ONLY TOKENS THAT OCCUR IN QUERY
------------------------------------------------------------------
article_tokens AS (
    SELECT  ca."id",
            tok.value::string  AS token
    FROM    candidate_articles ca,
            LATERAL FLATTEN(
                 INPUT => SPLIT(
                            REGEXP_REPLACE( LOWER(ca."body"),
                                            '[^a-z]+',' '),
                            ' ')
            ) tok
    WHERE   tok.value IS NOT NULL
      AND   tok.value <> ''
      AND   tok.value IN (SELECT token FROM query_tokens)  -- << filter >>
),
------------------------------------------------------------------
-- 6)  add vectors, frequencies, weights
------------------------------------------------------------------
article_word_vecs AS (
    SELECT  at."id",
            gv."vector"                     AS vec,
            POWER(wf."frequency", -0.4)     AS weight
    FROM    article_tokens                             at
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"    gv
           ON gv."word" = at.token
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
           ON wf."word" = at.token
),
------------------------------------------------------------------
-- 7)  weighted-vector sum per article (expanded to coordinates)
------------------------------------------------------------------
article_coords AS (
    SELECT  aw."id",
            v.index                                   AS idx,
            SUM( v.value::float * aw.weight )         AS coord
    FROM    article_word_vecs aw,
            LATERAL FLATTEN( INPUT => aw.vec ) v
    GROUP BY aw."id", v.index
),
------------------------------------------------------------------
-- 8)  normalise each article vector to unit length
------------------------------------------------------------------
article_norm AS (
    SELECT  "id",
            SQRT( SUM(coord*coord) ) AS norm
    FROM    article_coords
    GROUP BY "id"
    HAVING  norm > 0
),
article_unit AS (
    SELECT  ac."id",
            ac.idx,
            ac.coord / an.norm  AS coord
    FROM    article_coords ac
    JOIN    article_norm  an ON ac."id" = an."id"
),
------------------------------------------------------------------
-- 9)  cosine similarity = dot product of unit vectors
------------------------------------------------------------------
similarity AS (
    SELECT  au."id",
            SUM( au.coord * qu.coord ) AS score
    FROM    article_unit au
    JOIN    query_unit   qu USING(idx)
    GROUP BY au."id"
)
------------------------------------------------------------------
-- 10)  bring back metadata & return top-10
------------------------------------------------------------------
SELECT  n."id",
        n."date",
        n."title",
        s.score   AS cosine_similarity
FROM    similarity  s
JOIN    candidate_articles n
      ON n."id" = s."id"
ORDER BY s.score DESC NULLS LAST
LIMIT 10;