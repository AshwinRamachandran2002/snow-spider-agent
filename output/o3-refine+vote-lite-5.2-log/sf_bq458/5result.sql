/* ----------------------------------------------------------
   Build a normalised vector for every Nature article
   (use per‑article word counts to reduce row explosion)
-----------------------------------------------------------*/
WITH stop_words(word) AS (
    SELECT column1 FROM VALUES
        ('a'),('an'),('the'),('and'),('or'),('but'),('if'),('then'),('else'),
        ('when'),('at'),('by'),('for'),('in'),('of'),('on'),('to'),('with'),
        ('without'),('is'),('are'),('was'),('were'),('be'),('been'),('being')
),

/* 1. Tokenise article body; remove punctuation, blanks & stop words */
tokens AS (
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(REGEXP_REPLACE(f.value::string,'[^a-z0-9]','')) AS token
    FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n,
         LATERAL FLATTEN(INPUT => SPLIT(LOWER(n."body"),' ')) f
    WHERE LOWER(REGEXP_REPLACE(f.value::string,'[^a-z0-9]','')) <> ''
      AND LOWER(REGEXP_REPLACE(f.value::string,'[^a-z0-9]',''))
          NOT IN (SELECT word FROM stop_words)
),

/* 2. Count occurrences of each remaining token per article */
word_counts AS (
    SELECT
        "id",
        "date",
        "title",
        token,
        COUNT(*) AS cnt
    FROM tokens
    GROUP BY "id","date","title",token
),

/* 3. Join with frequency table & glove vectors, compute weight */
scaled_vectors AS (
    SELECT
        wc."id",
        wc."date",
        wc."title",
        gv."vector"                                         AS vec,
        wc.cnt / POWER(wf."frequency", 0.4)                 AS scale
    FROM word_counts wc
         JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
              ON wf."word" = wc.token
         JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"  gv
              ON gv."word" = wc.token
),

/* 4. Multiply each vector element by its scale and flatten once       */
flattened AS (
    SELECT
        sv."id",
        sv."date",
        sv."title",
        fv.index                                   AS dim,
        fv.value::FLOAT * sv.scale                 AS val
    FROM scaled_vectors sv,
         LATERAL FLATTEN(INPUT => sv.vec) fv
),

/* 5. Sum weighted components per article                              */
summed AS (
    SELECT
        "id",
        "date",
        "title",
        dim,
        SUM(val)                                    AS component
    FROM flattened
    GROUP BY "id","date","title",dim
),

/* 6. Assemble raw vector & magnitude                                  */
article_vectors AS (
    SELECT
        "id",
        "date",
        "title",
        ARRAY_AGG(component) WITHIN GROUP (ORDER BY dim) AS raw_vec,
        SQRT(SUM(component * component))                 AS magnitude
    FROM summed
    GROUP BY "id","date","title"
)

/* 7. Normalise vector and output                                      */
SELECT
    av."id",
    av."date",
    av."title",
    ARRAY_AGG( s.component / av.magnitude )
          WITHIN GROUP (ORDER BY s.dim)           AS normalized_article_vector
FROM article_vectors av
     JOIN summed s
          ON s."id" = av."id"
         AND s."date" = av."date"
         AND s."title" = av."title"
WHERE av.magnitude <> 0
GROUP BY av."id", av."date", av."title", av.magnitude;