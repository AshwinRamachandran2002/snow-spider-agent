WITH
/* ---------------------- stop‑word list ---------------------- */
stopwords(word) AS (
    SELECT column1
    FROM VALUES
        ('the'),('and'),('a'),('an'),('in'),('on'),('for'),('to'),('of'),('with'),
        ('is'),('are'),('was'),('were'),('be'),('been'),('being'),('by'),('this'),
        ('that'),('these'),('those'),('at'),('from'),('it'),('as'),('or'),('but'),
        ('if'),('then'),('else'),('into'),('out'),('about'),('so'),('such'),
        ('their'),('its'),('our')
),

/* ---------------- build weighted QUERY vector --------------- */
query_tokens AS (
    SELECT tk.value::string AS token
    FROM (
        SELECT SPLIT(
                 LOWER(
                     REGEXP_REPLACE(
                         'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',
                         '[^a-zA-Z ]',' ')
                 ), ' '
             ) AS arr
    ) q
    CROSS JOIN LATERAL FLATTEN(input => q.arr) tk
    LEFT  JOIN stopwords s ON s.word = tk.value::string
    WHERE tk.value::string <> ''       -- non‑empty
      AND s.word IS NULL               -- not a stop‑word
),
query_vecs AS (
    SELECT gv."vector" AS vec,
           POWER(COALESCE(wf."frequency",1),0.4) AS freq_p04
    FROM query_tokens qt
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = qt.token
    LEFT JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = qt.token
),
query_dims AS (
    SELECT f.index::int AS idx,
           SUM(f.value::float / qv.freq_p04) AS dim_val
    FROM query_vecs qv,
         LATERAL FLATTEN(input => qv.vec) f
    GROUP BY idx
),
query_norm AS (
    SELECT SQRT(SUM(POWER(dim_val,2))) AS norm_q
    FROM query_dims
),

/* --------------- extract & weight article tokens ------------ */
article_tokens AS (
    SELECT n."id",
           tk.value::string AS token
    FROM WORD_VECTORS_US.WORD_VECTORS_US."NATURE" n
    CROSS JOIN LATERAL FLATTEN(
                 input => SPLIT(
                              LOWER(
                                  REGEXP_REPLACE(n."body",'[^a-zA-Z ]',' ')
                              ), ' ')
             ) tk
    LEFT JOIN stopwords s ON s.word = tk.value::string
    WHERE tk.value::string <> ''
      AND s.word IS NULL
),
article_vecs AS (
    SELECT at."id",
           gv."vector" AS vec,
           POWER(COALESCE(wf."frequency",1),0.4) AS freq_p04
    FROM article_tokens at
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = at.token
    LEFT JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = at.token
),
article_dims AS (
    SELECT av."id",
           f.index::int                       AS idx,
           SUM(f.value::float / av.freq_p04)  AS dim_val
    FROM article_vecs av,
         LATERAL FLATTEN(input => av.vec) f
    GROUP BY av."id", idx
),
article_norms AS (
    SELECT "id",
           SQRT(SUM(POWER(dim_val,2))) AS norm_a
    FROM article_dims
    GROUP BY "id"
),

/* ---------------------- cosine similarity ------------------- */
dot_products AS (
    SELECT ad."id",
           SUM(ad.dim_val * qd.dim_val) AS dot_val
    FROM article_dims ad
    JOIN query_dims qd USING (idx)
    GROUP BY ad."id"
),
cosine_scores AS (
    SELECT dp."id",
           n."date",
           n."title",
           dp.dot_val / (an.norm_a * qn.norm_q) AS cosine_sim
    FROM dot_products  dp
    JOIN article_norms an
         ON an."id" = dp."id"        AND an.norm_a > 0
    JOIN WORD_VECTORS_US.WORD_VECTORS_US."NATURE" n
         ON n."id" = dp."id"
    CROSS JOIN query_norm qn
)

/* ---------------- top 10 most similar papers ---------------- */
SELECT "id",
       "date",
       "title",
       cosine_sim
FROM   cosine_scores
ORDER  BY cosine_sim DESC NULLS LAST
LIMIT  10;