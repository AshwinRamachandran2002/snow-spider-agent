WITH stop_words(word) AS (        -- minimal stop‑word list
    SELECT column1 FROM VALUES
        ('a'),('an'),('the'),('and'),('or'),('but'),('is'),('are'),('was'),('were'),
        ('in'),('on'),('at'),('of'),('for'),('to'),('from'),('by'),('with'),('as'),
        ('that'),('this'),('these'),('those'),('be'),('been'),('being'),('it'),('its'),
        ('he'),('she'),('they'),('them'),('his'),('her'),('their'),('we'),('us'),
        ('our'),('you'),('your'),('i'),('me'),('my')
),

/* ------------------------------------------------------------------
   1. tokenise article bodies, lower‑case, strip punctuation
-------------------------------------------------------------------*/
tokens AS (
    SELECT  n."id",
            n."date",
            n."title",
            LOWER(TRIM(tok.value::string)) AS word
    FROM    WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
            LATERAL FLATTEN(
                INPUT => SPLIT(
                           REGEXP_REPLACE(n."body", '[^A-Za-z0-9 ]', ' '),
                           ' ')
            ) tok
    WHERE tok.value IS NOT NULL
),

/* ------------------------------------------------------------------
   2. remove stop words and blanks
-------------------------------------------------------------------*/
filtered_tokens AS (
    SELECT  t."id", t."date", t."title", t.word
    FROM    tokens t
    LEFT JOIN stop_words s
           ON t.word = s.word
    WHERE   s.word IS NULL
      AND   t.word <> ''
),

/* ------------------------------------------------------------------
   3. count occurrences of every word in each article
-------------------------------------------------------------------*/
word_counts AS (
    SELECT  "id","date","title", word, COUNT(*) AS word_cnt
    FROM    filtered_tokens
    GROUP BY "id","date","title", word
),

/* ------------------------------------------------------------------
   4. join counts with vectors & corpus frequency
-------------------------------------------------------------------*/
word_data AS (
    SELECT  wc."id",
            wc."date",
            wc."title",
            wc.word,
            wc.word_cnt,
            COALESCE(wf."frequency",1) AS freq,
            gv."vector"                AS vector
    FROM    word_counts wc
    JOIN    WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
           ON gv."word" = wc.word
    LEFT JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
           ON wf."word" = wc.word
),

/* ------------------------------------------------------------------
   5. weight every vector component                             
-------------------------------------------------------------------*/
weighted_components AS (
    SELECT  wd."id",
            wd."date",
            wd."title",
            v.index AS idx,
            (v.value::FLOAT) * wd.word_cnt / POWER(wd.freq,0.4) AS comp
    FROM    word_data wd,
            LATERAL FLATTEN(INPUT => wd.vector) v
),

/* ------------------------------------------------------------------
   6. sum weighted components → raw article vectors
-------------------------------------------------------------------*/
article_raw AS (
    SELECT  "id","date","title", idx, SUM(comp) AS comp_sum
    FROM    weighted_components
    GROUP BY "id","date","title", idx
),

/* ------------------------------------------------------------------
   7. magnitude of each raw vector
-------------------------------------------------------------------*/
article_mag AS (
    SELECT  "id","date","title",
            SQRT(SUM(comp_sum*comp_sum)) AS mag
    FROM    article_raw
    GROUP BY "id","date","title"
),

/* ------------------------------------------------------------------
   8. normalise components
-------------------------------------------------------------------*/
article_norm AS (
    SELECT  r."id",
            r."date",
            r."title",
            r.idx,
            r.comp_sum / NULLIF(m.mag,0) AS comp_norm
    FROM    article_raw r
    JOIN    article_mag m
           ON r."id"   = m."id"
          AND r."date" = m."date"
          AND r."title"= m."title"
)

/* ------------------------------------------------------------------
   9. build final article vectors
-------------------------------------------------------------------*/
SELECT  "id",
        "date",
        "title",
        ARRAY_AGG(comp_norm) WITHIN GROUP (ORDER BY idx) AS article_vector
FROM    article_norm
GROUP BY "id","date","title";