/*-----------------------------------------------------------
  Build article and query vectors with TF / freq^0.4 weighting
  (TF = term‑frequency inside the document).  We aggregate on
  words first, so every word vector is processed only once per
  article ─ this keeps the row count low and avoids timeout.
-----------------------------------------------------------*/
WITH
/* ---------- tiny stop‑word list ---------- */
stopwords(word) AS (
    SELECT column1 FROM VALUES
      ('the'),('and'),('in'),('of'),('to'),('a'),('is'),('for'),('on'),('with'),
      ('that'),('by'),('as'),('are'),('at'),('an'),('be'),('this'),('from'),
      ('which'),('or'),('it'),('its'),('we'),('our'),('they'),('their'),('was'),
      ('were'),('has'),('have'),('had'),('but'),('not'),('can'),('such'),
      ('these'),('also'),('may'),('using'),('used')
),

/* ---------- frequency and GloVe vector together ---------- */
word_info AS (
    SELECT  f."word"                  AS word,
            f."frequency"::FLOAT      AS freq,
            g."vector"                AS vector
    FROM    WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES f
    JOIN    WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    g
            ON g."word" = f."word"
),

/* ---------- tokenise every article body ---------- */
article_tokens AS (
    SELECT  n."id",
            n."date",
            n."title",
            LOWER(tok.value::STRING) AS word
    FROM    WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
            LATERAL FLATTEN( INPUT =>
                    SPLIT(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(n."body", '[^A-Za-z ]', ' '),  -- keep letters
                            ' +', ' '                                     -- collapse spaces
                        ),
                        ' '
                    )
            ) tok
    WHERE   tok.value IS NOT NULL
      AND   tok.value <> ''
      AND   LOWER(tok.value::STRING) NOT IN (SELECT word FROM stopwords)
),

/* ---------- term‑frequency of each word inside each article ---------- */
article_word_counts AS (
    SELECT  "id", "date", "title", word, COUNT(*) AS tf
    FROM    article_tokens
    GROUP   BY "id", "date", "title", word
),

/* ---------- attach vectors & frequencies ---------- */
article_word_vectors AS (
    SELECT  c."id",
            c."date",
            c."title",
            c.tf,
            w.freq,
            w.vector
    FROM    article_word_counts c
    JOIN    word_info           w  ON w.word = c.word
),

/* ---------- expand vectors, multiply once per word ---------- */
article_components AS (
    SELECT  "id",
            "date",
            "title",
            comp.index                                           AS idx,
            (c.tf / POW(freq, 0.4)) * comp.value::FLOAT          AS weighted_value
    FROM    article_word_vectors  c,
            LATERAL FLATTEN(INPUT => vector) comp
),

/* ---------- summed vector per article ---------- */
article_sum AS (
    SELECT  "id", "date", "title", idx,
            SUM(weighted_value) AS comp_value
    FROM    article_components
    GROUP   BY "id", "date", "title", idx
),

/* ---------- magnitude per article ---------- */
article_mag AS (
    SELECT  "id",
            SQRT(SUM(comp_value * comp_value)) AS mag
    FROM    article_sum
    GROUP   BY "id"
    HAVING  mag > 0
),

/* ---------- tokenise query phrase ---------- */
query_tokens AS (
    SELECT LOWER(tok.value::STRING) AS word
    FROM   LATERAL FLATTEN( INPUT =>
               SPLIT(
                   REGEXP_REPLACE(
                       REGEXP_REPLACE(
                         'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',
                         '[^A-Za-z ]', ' '
                       ),
                       ' +', ' '
                   ),
                   ' '
               )
           ) tok
    WHERE  tok.value IS NOT NULL
      AND  tok.value <> ''
      AND  LOWER(tok.value::STRING) NOT IN (SELECT word FROM stopwords)
),

/* ---------- term‑frequency of words in query ---------- */
query_word_counts AS (
    SELECT word, COUNT(*) AS tf
    FROM   query_tokens
    GROUP  BY word
),

/* ---------- attach vectors & frequencies ---------- */
query_word_vectors AS (
    SELECT  q.tf,
            w.freq,
            w.vector
    FROM    query_word_counts q
    JOIN    word_info         w  ON w.word = q.word
),

/* ---------- expand & weight query vector ---------- */
query_components AS (
    SELECT  comp.index                                AS idx,
            SUM( (q.tf / POW(freq,0.4)) * comp.value::FLOAT ) AS comp_value
    FROM    query_word_vectors q,
            LATERAL FLATTEN(INPUT => vector) comp
    GROUP   BY idx
),

/* ---------- magnitude of query vector ---------- */
query_mag AS (
    SELECT SQRT(SUM(comp_value * comp_value)) AS mag
    FROM   query_components
    HAVING mag > 0
),

/* ---------- cosine similarity query vs article ---------- */
similarity AS (
    SELECT  a."id",
            a."date",
            a."title",
            SUM(a.comp_value * q.comp_value) / (am.mag * qm.mag)  AS cosine
    FROM        article_sum      a
    JOIN        query_components q  ON q.idx = a.idx
    JOIN        article_mag      am ON am."id" = a."id"
    CROSS JOIN  query_mag        qm
    GROUP BY    a."id", a."date", a."title", am.mag, qm.mag
)

/* ---------- top‑10 most similar articles ---------- */
SELECT  "id",
        "date",
        "title",
        cosine
FROM    similarity
ORDER BY cosine DESC NULLS LAST, "id"
LIMIT 10;