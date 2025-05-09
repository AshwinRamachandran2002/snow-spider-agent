/* ----------  find the 10 Nature articles most similar to the query  ---------- */
WITH
/* -------------------------------  stop‑word list  ------------------------------- */
stopwords(word) AS (
    SELECT column1 FROM VALUES
        ('the'), ('and'), ('a'), ('an'), ('of'), ('to'), ('in'),
        ('for'), ('on'), ('with'), ('at'), ('by'), ('from'), ('up'),
        ('about'), ('into'), ('over'), ('after'), ('before'),
        ('between'), ('under'), ('again'), ('further'), ('then'),
        ('once'), ('here'), ('there'), ('all'), ('any'), ('both'),
        ('each'), ('few'), ('more'), ('most'), ('other'), ('some'),
        ('such'), ('no'), ('nor'), ('not'), ('only'), ('own'),
        ('same'), ('so'), ('than'), ('too'), ('very')
),

/* --------------------  tokenise every article body  -------------------- */
article_tokens AS (
    SELECT
        art."id"   AS id,
        art."date" AS article_date,
        art."title" AS title,
        LOWER(tok.value) AS token
    FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" art
    CROSS JOIN LATERAL FLATTEN(
        INPUT => SPLIT(
                    REGEXP_REPLACE(art."body", '[^A-Za-z ]', ' '),
                    ' '
                )
    ) tok
    WHERE tok.value IS NOT NULL
      AND tok.value <> ''
),

/* ----  keep tokens that are in vocabulary and not a stop‑word  ---- */
article_token_vectors AS (
    SELECT
        at.id,
        at.article_date,
        at.title,
        gv."vector"                       AS vector,
        1 / POWER(wf."frequency", 0.4)    AS weight
    FROM article_tokens at
    LEFT  JOIN stopwords sw ON sw.word = at.token
    JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
         ON wf."word" = at.token
    JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"    gv
         ON gv."word" = at.token
    WHERE sw.word IS NULL
),

/* ----------  sum weighted values per vector dimension (article)  ---------- */
article_dim_values AS (
    SELECT
        atv.id,
        atv.article_date,
        atv.title,
        vec.index::INT                                   AS dim,
        SUM(vec.value::FLOAT * atv.weight)               AS dim_value
    FROM article_token_vectors atv,
         LATERAL FLATTEN(INPUT => atv.vector) vec
    GROUP BY atv.id, atv.article_date, atv.title, vec.index
),

/* ---------------------------  normalise vectors  --------------------------- */
article_norms AS (
    SELECT
        id,
        article_date,
        title,
        SQRT(SUM(dim_value * dim_value)) AS norm
    FROM article_dim_values
    GROUP BY id, article_date, title
),

article_unit AS (
    SELECT
        d.id,
        d.article_date,
        d.title,
        d.dim,
        d.dim_value / n.norm AS value
    FROM article_dim_values d
    JOIN article_norms n
      ON n.id = d.id
     AND n.article_date = d.article_date
     AND n.title        = d.title
    WHERE n.norm > 0
),

/* =======================   query processing   ======================= */
query_tokens AS (
    SELECT LOWER(tok.value) AS token
    FROM LATERAL FLATTEN(
             INPUT => SPLIT(
                 REGEXP_REPLACE(
                     'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',
                     '[^A-Za-z ]',
                     ' '
                 ),
                 ' '
             )
         ) tok
    WHERE tok.value IS NOT NULL
      AND tok.value <> ''
),

query_token_vectors AS (
    SELECT
        gv."vector"                    AS vector,
        1 / POWER(wf."frequency", 0.4) AS weight
    FROM query_tokens qt
    LEFT  JOIN stopwords sw ON sw.word = qt.token
    JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
         ON wf."word" = qt.token
    JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"    gv
         ON gv."word" = qt.token
    WHERE sw.word IS NULL
),

query_dim_values AS (
    SELECT
        vec.index::INT                          AS dim,
        SUM(vec.value::FLOAT * qtv.weight)      AS dim_value
    FROM query_token_vectors qtv,
         LATERAL FLATTEN(INPUT => qtv.vector) vec
    GROUP BY vec.index
),

query_norm AS (
    SELECT SQRT(SUM(dim_value * dim_value)) AS norm FROM query_dim_values
),

query_unit AS (
    SELECT
        qdv.dim,
        qdv.dim_value / qn.norm AS value
    FROM query_dim_values qdv, query_norm qn
    WHERE qn.norm > 0
)

/* ====================  cosine similarity & top‑10  ==================== */
SELECT
    au.id,
    au.article_date AS date,
    au.title,
    SUM(au.value * qu.value) AS cosine_similarity
FROM article_unit au
JOIN query_unit  qu
  ON qu.dim = au.dim
GROUP BY au.id, au.article_date, au.title
ORDER BY cosine_similarity DESC NULLS LAST, au.id
LIMIT 10;