WITH
/* ---------------- stop-word list ---------------- */
stopwords(word) AS (
    SELECT column1 FROM VALUES
        ('a'),('an'),('and'),('are'),('as'),('at'),('be'),('by'),('for'),
        ('from'),('in'),('is'),('it'),('of'),('on'),('or'),('that'),
        ('the'),('this'),('to'),('was'),('were'),('with')
),

/* ---------------- query tokens ------------------ */
query_tokens AS (
    SELECT DISTINCT LOWER(TRIM(tok.value::STRING)) AS token
    FROM ( SELECT
               'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders' AS q
         ) src
    CROSS JOIN LATERAL FLATTEN(
                 INPUT => SPLIT(
                              REGEXP_REPLACE(LOWER(src.q), '[^a-z0-9 ]', ' '),
                              ' ')
             ) tok
    WHERE tok.value::STRING <> ''
      AND LOWER(TRIM(tok.value::STRING)) NOT IN (SELECT word FROM stopwords)
),
query_token_vectors AS (   /* weight each query token */
    SELECT
        qt.token,
        1 / POWER(wf."frequency", 0.4)                     AS weight,
        gv."vector"                                        AS vec
    FROM query_tokens qt
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = qt.token
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = qt.token
),

/* flatten query vectors into (idx , value) components */
query_components AS (
    SELECT
        fv.index                                           AS idx,
        SUM(qtv.weight * fv.value::FLOAT)                  AS comp
    FROM query_token_vectors qtv
    ,    LATERAL FLATTEN(INPUT => qtv.vec) fv
    GROUP BY fv.index
),
query_norm AS (
    SELECT SQRT(SUM(comp * comp)) AS q_norm
    FROM query_components
),

/* --------- article: only words that appear in query --------- */
article_token_counts AS (
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(TRIM(tok.value::STRING))                     AS token,
        COUNT(*)                                           AS cnt
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
    CROSS JOIN LATERAL FLATTEN(
                 INPUT => SPLIT(
                              REGEXP_REPLACE(LOWER(n."body"), '[^a-z0-9 ]', ' '),
                              ' ')
             ) tok
    WHERE tok.value::STRING <> ''
      AND LOWER(TRIM(tok.value::STRING)) IN (SELECT token FROM query_tokens)      -- keep only relevant tokens
      AND LOWER(TRIM(tok.value::STRING)) NOT IN (SELECT word FROM stopwords)
    GROUP BY n."id", n."date", n."title", token
),

article_token_vectors AS (        /* weight by count */
    SELECT
        atc."id",
        atc."date",
        atc."title",
        atc.token,
        (atc.cnt / POWER(wf."frequency", 0.4))             AS weight,
        gv."vector"                                        AS vec
    FROM article_token_counts atc
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = atc.token
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = atc.token
),

/* flatten weighted article vectors */
article_components AS (
    SELECT
        atv."id",
        atv."date",
        atv."title",
        fv.index                                           AS idx,
        SUM(atv.weight * fv.value::FLOAT)                  AS comp
    FROM article_token_vectors atv
    ,    LATERAL FLATTEN(INPUT => atv.vec) fv
    GROUP BY atv."id", atv."date", atv."title", fv.index
),

/* compute article norms */
article_norms AS (
    SELECT
        "id",
        MAX("date")  AS "date",
        MAX("title") AS "title",
        SQRT(SUM(comp * comp))                            AS article_norm
    FROM article_components
    GROUP BY "id"
),

/* dot product between article & query vectors (only indices in query) */
dot_products AS (
    SELECT
        ac."id",
        SUM(ac.comp * qc.comp)                            AS dot
    FROM article_components ac
    JOIN query_components  qc
          ON qc.idx = ac.idx
    GROUP BY ac."id"
),

/* cosine similarity */
similarities AS (
    SELECT
        an."id",
        an."date",
        an."title",
        CASE
            WHEN an.article_norm > 0 AND qn.q_norm > 0
            THEN dp.dot / (an.article_norm * qn.q_norm)
            ELSE NULL
        END                                              AS similarity
    FROM article_norms an
    JOIN dot_products dp ON dp."id" = an."id"
    CROSS JOIN query_norm qn
)

SELECT
    "id",
    "date",
    "title",
    similarity
FROM similarities
ORDER BY similarity DESC NULLS LAST
LIMIT 10;