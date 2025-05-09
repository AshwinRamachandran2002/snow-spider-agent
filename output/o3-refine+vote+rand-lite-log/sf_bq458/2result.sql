/* -----------------------------------------------------------
   Build a unit‑length vector for every Nature article while
   minimising row explosion (flatten only once for each UNIQUE
   word in an article, not for every occurrence).
   ----------------------------------------------------------- */
WITH stop_words AS (                 -- small stop‑word list
    SELECT column1 AS word FROM VALUES
        ('the'),('and'),('is'),('in'),('of'),('to'),('a'),('with'),('for'),('on'),
        ('that'),('this'),('by'),('be'),('are'),('as'),('we'),('an'),('it'),('from'),
        ('at'),('or')
),

articles AS (                        -- pick required columns
    SELECT  "id",
            "date",
            "title",
            LOWER("body") AS body_txt
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE
),

/* tokenise once, then count each word per article */
token_counts AS (
    SELECT  a."id",
            a."date",
            a."title",
            TRIM(tok.value::string)  AS word,
            COUNT(*)                 AS cnt
    FROM    articles a,
            LATERAL SPLIT_TO_TABLE(
                     REGEXP_REPLACE(a.body_txt, '[^a-z ]', ' '), ' ') tok
    WHERE   tok.value IS NOT NULL
      AND   tok.value <> ''
      AND   tok.value::string NOT IN (SELECT word FROM stop_words)
    GROUP BY a."id", a."date", a."title", TRIM(tok.value::string)
),

/* attach corpus frequency & glove vector */
word_info AS (
    SELECT  tc."id",
            tc."date",
            tc."title",
            tc.word,
            tc.cnt,
            wf."frequency",
            gv."vector"
    FROM    token_counts tc
    JOIN    WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES  wf
           ON wf."word" = tc.word
    JOIN    WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS     gv
           ON gv."word" = tc.word
),

/* weight each component, multiplying by the word count */
weighted AS (
    SELECT  wi."id",
            wi."date",
            wi."title",
            v.index AS idx,
            (v.value::FLOAT * wi.cnt) / POWER(wi."frequency", 0.4) AS w_val
    FROM    word_info wi,
            LATERAL FLATTEN(input => wi."vector") v
),

/* sum weighted components per article */
article_sum AS (
    SELECT  "id",
            "date",
            "title",
            idx,
            SUM(w_val) AS comp
    FROM    weighted
    GROUP BY "id", "date", "title", idx
),

/* compute magnitude of each article vector */
magnitude AS (
    SELECT  "id",
            "date",
            "title",
            SQRT(SUM(comp * comp)) AS mag
    FROM    article_sum
    GROUP BY "id", "date", "title"
),

/* normalise and build ordered array */
normalised AS (
    SELECT  s."id",
            s."date",
            s."title",
            ARRAY_AGG( s.comp / IFF(m.mag = 0, 1, m.mag) )
              WITHIN GROUP (ORDER BY s.idx)   AS article_vector
    FROM    article_sum s
    JOIN    magnitude m
      ON    m."id"   = s."id"
     AND    m."date" = s."date"
     AND    m."title"= s."title"
    GROUP BY s."id", s."date", s."title", m.mag
)

SELECT  "id",
        "date",
        "title",
        article_vector
FROM    normalised;