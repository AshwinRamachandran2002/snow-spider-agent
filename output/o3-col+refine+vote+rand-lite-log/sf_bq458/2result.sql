/* ---------------------------------------------------------------
   Build a unit-length (normalised) vector for every Nature article
   – tokenise, count, weight, sum, and normalise
   ---------------------------------------------------------------*/
WITH
/* 1) stop-word list (small) ------------------------------------ */
STOP_WORDS AS (
    SELECT COLUMN1 AS WORD
    FROM VALUES
        ('the'),('of'),('and'),('in'),('to'),('a'),('with'),('for'),('is'),('on'),
        ('that'),('was'),('were'),('as'),('by'),('from'),('at'),('this'),('an'),
        ('be'),('are'),('or'),('which'),('it'),('we'),('has'),('have'),('had'),
        ('not'),('but'),('can'),('its'),('his'),('her'),('their'),('they')
),

/* 2) clean body text (lower-case; alphabetic only) -------------- */
CLEAN_ARTICLE AS (
    SELECT   n."id",
             n."date",
             n."title",
             LOWER(REGEXP_REPLACE(n."body",'[^A-Za-z]+',' ')) AS clean_text
    FROM     "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n
),

/* 3) tokenise & count words per article (excluding stop words) -- */
ARTICLE_WORD_COUNTS AS (
    SELECT  ca."id",
            ca."date",
            ca."title",
            TRIM(tok.value)::STRING      AS word,
            COUNT(*)                     AS word_count
    FROM    CLEAN_ARTICLE ca,
            LATERAL SPLIT_TO_TABLE(ca.clean_text,' ') tok
    WHERE   tok.value <> ''
      AND   tok.value NOT IN (SELECT WORD FROM STOP_WORDS)
    GROUP BY ca."id", ca."date", ca."title", TRIM(tok.value)
),

/* 4) join frequency and glove vector once per word -------------- */
WORD_INFO AS (
    SELECT  awc."id",
            awc."date",
            awc."title",
            awc.word,
            awc.word_count,
            wf."frequency",
            gv."vector"
    FROM    ARTICLE_WORD_COUNTS awc
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
           ON wf."word" = awc.word
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS" gv
           ON gv."word" = awc.word
),

/* 5) flatten each word’s vector and apply weighting ------------- */
WORD_COMPONENTS AS (
    SELECT  wi."id",
            wi."date",
            wi."title",
            f.index                                         AS idx,
            ( f.value::FLOAT
              * wi.word_count )
              / POWER( wi."frequency", 0.4 )                AS weighted_val
    FROM    WORD_INFO wi,
            LATERAL FLATTEN( input => wi."vector" ) f
),

/* 6) sum weighted components per article ------------------------ */
ARTICLE_COMPONENT_SUMS AS (
    SELECT  "id","date","title", idx,
            SUM(weighted_val)           AS comp_sum
    FROM    WORD_COMPONENTS
    GROUP BY "id","date","title", idx
),

/* 7) build summed vector array & magnitude ---------------------- */
VECTORS_WITH_MAG AS (
    SELECT  "id","date","title",
            ARRAY_AGG(comp_sum) WITHIN GROUP (ORDER BY idx)  AS vec,
            SQRT( SUM(comp_sum*comp_sum) )                   AS mag
    FROM    ARTICLE_COMPONENT_SUMS
    GROUP BY "id","date","title"
),

/* 8) normalise each component by magnitude ---------------------- */
NORMALISED AS (
    SELECT  vwm."id",
            vwm."date",
            vwm."title",
            ARRAY_AGG( (vf.value::FLOAT) / NULLIF(vwm.mag,0) )
              WITHIN GROUP (ORDER BY vf.index)               AS article_vector
    FROM    VECTORS_WITH_MAG vwm,
            LATERAL FLATTEN( input => vwm.vec ) vf
    GROUP BY vwm."id", vwm."date", vwm."title"
)

SELECT  "id",
        "date",
        "title",
        article_vector
FROM    NORMALISED;