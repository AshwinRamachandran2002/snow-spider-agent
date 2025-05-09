/* -------------------------------------------------------------
   Build a per‑article GloVe embedding with frequency‑based
   weighting, grouping repeated words first to reduce workload
-------------------------------------------------------------*/
WITH
/* 0. stop‑word list ------------------------------------------------------- */
stopwords(word) AS (
    SELECT column1
    FROM VALUES
        ('a'),('an'),('the'),('and'),('or'),('but'),('if'),('while'),('with'),
        ('to'),('of'),('in'),('on'),('for'),('by'),('is'),('are'),('was'),
        ('were'),('be'),('been'),('being'),('that'),('this'),('these'),
        ('those'),('as'),('at'),('from'),('it'),('its'),('he'),('she'),
        ('they'),('them'),('his'),('her'),('their'),('we'),('us'),('our'),
        ('you'),('your'),('i'),('me'),('my'),('mine')
),

/* 1. tokenise article body ----------------------------------------------- */
tokens AS (
    SELECT
        n."id"            AS id,
        n."date"          AS article_date,
        n."title"         AS title,
        LOWER(REGEXP_REPLACE(t.value::string,'[^a-z]','')) AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                        LOWER(REGEXP_REPLACE(n."body",'[^a-z ]',' ')),
                        ' ')
         ) t
    WHERE t.value IS NOT NULL
      AND t.value <> ''
),

/* 2. drop stop‑words & count word occurrences per article ----------------- */
word_counts AS (
    SELECT
        id,
        article_date,
        title,
        word,
        COUNT(*) AS cnt        -- repetitions of the word in this article
    FROM tokens
    WHERE word NOT IN (SELECT word FROM stopwords)
    GROUP BY id, article_date, title, word
),

/* 3. attach vectors & corpus frequencies, compute total weight ------------ */
word_vecs AS (
    SELECT
        wc.id,
        wc.article_date,
        wc.title,
        gv."vector"                                  AS vec,
        (wc.cnt * POWER(wf."frequency", -0.4))       AS weight  -- cnt × freq^-0.4
    FROM word_counts wc
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS     gv
          ON gv."word" = wc.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES  wf
          ON wf."word" = wc.word
),

/* 4. multiply each vector component by its weight ------------------------- */
weighted_components AS (
    SELECT
        id,
        article_date,
        title,
        f.index                         AS pos,
        f.value::FLOAT * weight         AS comp_val
    FROM word_vecs,
         LATERAL FLATTEN(INPUT => vec) f
),

/* 5. sum components per article ------------------------------------------ */
article_components AS (
    SELECT
        id,
        article_date,
        title,
        pos,
        SUM(comp_val) AS comp_sum
    FROM weighted_components
    GROUP BY id, article_date, title, pos
),

/* 6. compute vector magnitudes ------------------------------------------- */
magnitudes AS (
    SELECT
        id,
        article_date,
        title,
        SQRT(SUM(comp_sum * comp_sum)) AS mag
    FROM article_components
    GROUP BY id, article_date, title
    HAVING mag > 0        -- safeguard against zero vectors
),

/* 7. normalise components & assemble array ------------------------------- */
normalised AS (
    SELECT
        ac.id,
        ac.article_date,
        ac.title,
        ARRAY_AGG(ac.comp_sum / m.mag)
            WITHIN GROUP (ORDER BY ac.pos)           AS article_vector
    FROM article_components ac
    JOIN magnitudes m
          ON  ac.id = m.id
          AND ac.article_date = m.article_date
          AND ac.title = m.title
    GROUP BY ac.id, ac.article_date, ac.title
)

/* 8. final result --------------------------------------------------------- */
SELECT
    id,
    article_date AS "date",
    title,
    article_vector
FROM normalised;