WITH
--------------------------------------------------------------
-- 1. stop‑word list
--------------------------------------------------------------
stopwords(word) AS (
    SELECT * FROM VALUES
        ('a'),('an'),('and'),('the'),('in'),('on'),('for'),('of'),('with'),('to'),
        ('is'),('are'),('as'),('by'),('from'),('this'),('that'),('these'),('those'),
        ('be'),('or'),('at'),('it'),('its')
),

--------------------------------------------------------------
-- 2. build weighted‑and‑normalised query vector
--------------------------------------------------------------
raw_query_tokens AS (
    SELECT LOWER(REGEXP_REPLACE(tok.value::STRING,'[^a-z]','')) AS token
    FROM LATERAL SPLIT_TO_TABLE(
            'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',
            ' '
    ) tok
),
query_tokens AS (
    SELECT token
    FROM raw_query_tokens
    WHERE token <> ''
      AND LENGTH(token) >= 3
      AND token NOT IN (SELECT word FROM stopwords)
),
query_wordinfo AS (
    SELECT g."vector"        AS vec,
           wf."frequency"    AS freq
    FROM query_tokens qt
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    g  ON g."word" = qt.token
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = qt.token
),
query_components AS (
    SELECT  f.index AS idx,
            SUM( (f.value::FLOAT) / POWER(freq,0.4) ) AS val
    FROM   query_wordinfo,
           LATERAL FLATTEN(vec) f
    GROUP  BY f.index
),
query_norm AS (SELECT SQRT(SUM(val*val)) AS norm FROM query_components),
query_vector AS (
    SELECT idx,
           val / (SELECT norm FROM query_norm) AS qval
    FROM   query_components
),

--------------------------------------------------------------
-- 3. tokenize every article body and filter tokens
--------------------------------------------------------------
raw_article_tokens AS (
    SELECT n."id",
           n."date",
           n."title",
           LOWER(REGEXP_REPLACE(word.value::STRING,'[^a-z]','')) AS token
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL SPLIT_TO_TABLE(
             REGEXP_REPLACE(LOWER(n."body"), '[^a-z]', ' '),
             ' '
         ) word
    WHERE n."body" IS NOT NULL
),
article_tokens AS (
    SELECT *
    FROM raw_article_tokens
    WHERE token <> ''
      AND LENGTH(token) >= 3
      AND token NOT IN (SELECT word FROM stopwords)
      AND REGEXP_LIKE(token, '^[a-z]+$')
),

--------------------------------------------------------------
-- 4. join tokens to vectors & frequencies
--------------------------------------------------------------
article_wordinfo AS (
    SELECT at."id",
           at."date",
           at."title",
           gv."vector"      AS vec,
           wf."frequency"   AS freq
    FROM article_tokens at
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = at.token
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = at.token
),

--------------------------------------------------------------
-- 5. build weighted (unnormalised) article vectors
--------------------------------------------------------------
article_components AS (
    SELECT aw."id",
           aw."date",
           aw."title",
           f.index AS idx,
           SUM( (f.value::FLOAT) / POWER(freq,0.4) ) AS val
    FROM article_wordinfo aw,
         LATERAL FLATTEN(vec) f
    GROUP BY aw."id", aw."date", aw."title", f.index
),
article_norms AS (
    SELECT "id",
           "date",
           "title",
           SQRT(SUM(val*val)) AS norm
    FROM article_components
    GROUP BY "id", "date", "title"
),

--------------------------------------------------------------
-- 6. dot‑product of each article with query vector
--------------------------------------------------------------
article_dot AS (
    SELECT ac."id",
           ac."date",
           ac."title",
           SUM(ac.val * qv.qval) AS dot
    FROM article_components ac
    JOIN query_vector qv
      ON qv.idx = ac.idx
    GROUP BY ac."id", ac."date", ac."title"
),

--------------------------------------------------------------
-- 7. cosine similarity
--------------------------------------------------------------
article_similarity AS (
    SELECT ad."id",
           ad."date",
           ad."title",
           ad.dot / an.norm AS cosine_similarity
    FROM article_dot  ad
    JOIN article_norms an ON an."id" = ad."id"
    WHERE an.norm > 0
)

--------------------------------------------------------------
-- 8. top 10 most relevant articles
--------------------------------------------------------------
SELECT "id",
       "date",
       "title",
       ROUND(cosine_similarity,4) AS cosine_similarity
FROM   article_similarity
ORDER  BY cosine_similarity DESC NULLS LAST, "date" DESC
LIMIT 10;