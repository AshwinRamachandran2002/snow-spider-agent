/* ------------------------------------------------------------------
   Compute cosine-similarity between a query sentence and Nature
   articles (body field) using GloVe vectors with frequency re-weighting.
   Runtime is kept within limits by:
     • pre-filtering on key words, and
     • only analysing the first 4 000 characters of the body
     • limiting to the 100 most-recent matching articles
------------------------------------------------------------------*/
WITH
/* 0) Candidate articles (≤100, most recent, contain at least one keyword) */
candidate_articles AS (
    SELECT
        "id",
        "date",
        "title",
        SUBSTR("body",1,4000) AS body          -- trim very long texts
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE
    WHERE  LOWER("body") LIKE '%epigenetic%'
       OR  LOWER("body") LIKE '%cerebral%'
       OR  LOWER("body") LIKE '%organoid%'
       OR  LOWER("body") LIKE '%autism%'
       OR  LOWER("body") LIKE '%spectrum%'
       OR  LOWER("body") LIKE '%disorder%'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "date" DESC) <= 100
),

/* 1) Minimal stop-word list */
stopwords(word) AS (
    SELECT column1 FROM VALUES
    ('a'),('an'),('the'),('and'),('or'),('for'),('to'),('of'),('in'),
    ('on'),('with'),('is'),('are'),('was'),('were'),('be'),('been'),
    ('being'),('by'),('at'),('from'),('as'),('that'),('this'),('these'),
    ('those'),('it'),('its'),('we'),('our'),('you'),('your'),('they'),
    ('their'),('them'),('he'),('she'),('him'),('her'),('his'),('hers'),
    ('i'),('me'),('my'),('mine')
),

/* 2) Tokenise article bodies */
article_tokens AS (
    SELECT
        ca."id",
        ca."date",
        ca."title",
        TRIM(tok.VALUE::string) AS token
    FROM candidate_articles ca,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                         LOWER(REGEXP_REPLACE(ca.body, '[^a-z0-9 ]', ' ')),
                         ' ')
         ) tok
    WHERE tok.VALUE IS NOT NULL
      AND TRIM(tok.VALUE::string) <> ''
      AND TRIM(tok.VALUE::string) NOT IN (SELECT word FROM stopwords)
),

/* 3) Join with GloVe vectors and word frequencies; weight = freq^-0.4 */
token_info AS (
    SELECT
        at."id",
        at."date",
        at."title",
        gv."vector"                            AS vec,
        1 / POWER(wf."frequency", 0.4)         AS weight
    FROM article_tokens at
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv
      ON gv."word" = at.token
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
      ON wf."word" = at.token
),

/* 4) Sum weighted vectors per dimension for each article */
article_dim AS (
    SELECT
        ti."id",
        ti."date",
        ti."title",
        vec.index                       AS dim,
        SUM(vec.value * ti.weight)      AS dim_val
    FROM token_info ti,
         LATERAL FLATTEN(INPUT => ti.vec) vec
    GROUP BY ti."id", ti."date", ti."title", vec.index
),

/* 5) Convert each article vector to unit length */
article_norm AS (
    SELECT "id", SQRT(SUM(dim_val * dim_val)) AS norm
    FROM   article_dim
    GROUP  BY "id"
),
article_unit AS (
    SELECT
        ad."id",
        ad."date",
        ad."title",
        ad.dim,
        ad.dim_val / an.norm             AS value
    FROM article_dim ad
    JOIN article_norm an ON an."id" = ad."id"
    WHERE an.norm > 0
),

/* 6) Build unit-length query vector (same pipeline) */
query_tokens AS (
    SELECT TRIM(tok.VALUE::string) AS token
    FROM (SELECT LOWER(
            REGEXP_REPLACE(
              'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',
              '[^a-z0-9 ]', ' ')
          ) AS qtxt) q,
         LATERAL FLATTEN(INPUT => SPLIT(q.qtxt,' ')) tok
    WHERE tok.VALUE IS NOT NULL
      AND TRIM(tok.VALUE::string) <> ''
      AND TRIM(tok.VALUE::string) NOT IN (SELECT word FROM stopwords)
),
query_info AS (
    SELECT gv."vector" AS vec, 1/POWER(wf."frequency",0.4) AS weight
    FROM query_tokens qt
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv
      ON gv."word" = qt.token
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
      ON wf."word" = qt.token
),
query_dim AS (
    SELECT vec.index AS dim, SUM(vec.value * qi.weight) AS dim_val
    FROM query_info qi,
         LATERAL FLATTEN(INPUT => qi.vec) vec
    GROUP BY vec.index
),
query_unit AS (
    SELECT
        dim,
        dim_val / SQRT(SUM(dim_val * dim_val) OVER ()) AS value
    FROM query_dim
),

/* 7) Cosine similarity (dot product of two unit vectors) */
similarity AS (
    SELECT
        au."id",
        au."date",
        au."title",
        SUM(au.value * qu.value) AS similarity
    FROM article_unit au
    JOIN query_unit  qu ON au.dim = qu.dim
    GROUP BY au."id", au."date", au."title"
)

/* 8) Return the ten most similar articles */
SELECT
    "id",
    "date",
    "title",
    similarity
FROM similarity
ORDER BY similarity DESC NULLS LAST
LIMIT 10;