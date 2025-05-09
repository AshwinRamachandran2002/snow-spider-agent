/* ----------------------------------------------------------
   Build normalised article‑level vectors
-----------------------------------------------------------*/
WITH stop_words AS (
    SELECT column1 AS word FROM VALUES
        ('a'),('an'),('the'),('and'),('or'),('but'),('is'),('are'),('was'),('were'),('be'),('been'),('being'),
        ('have'),('has'),('had'),('do'),('does'),('did'),
        ('of'),('in'),('to'),('for'),('with'),('on'),('at'),('by'),('from'),('as'),('that'),('this'),('these'),('those'),
        ('it'),('its'),('he'),('she'),('they'),('them'),('we'),('us'),('you'),
        ('i'),('me'),('my'),('your'),('our'),('their'),
        ('not'),('no'),('can'),('could'),('should'),('would'),('will'),('shall'),('may'),('might'),('must'),
        ('if'),('then'),('else'),('when'),('while'),('which'),('who'),('whom'),('what'),('where'),('why'),('how'),
        ('so'),('than'),('too'),('very'),('also'),('such'),
        ('about'),('into'),('after'),('before'),('over'),('under'),('again'),('further'),('once')
),
/* 1. tokenize article body */
token_words AS (
    SELECT
        n."id"      AS "id",
        n."date"    AS "date",
        n."title"   AS "title",
        tk.value::STRING AS "word"
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             SPLIT(
                 REGEXP_REPLACE( LOWER(n."body"), '[^a-z]+', ' ' ),
                 ' '
             )
         ) tk
    WHERE tk.value::STRING <> ''
),
/* 2. remove stop‑words (keep duplicates for term‑frequency) */
filtered_tokens AS (
    SELECT
        t."id", t."date", t."title", t."word"
    FROM token_words t
    LEFT JOIN stop_words s
           ON t."word" = s.word
    WHERE s.word IS NULL
),
/* 3. join with glove vectors & word frequencies */
word_vectors AS (
    SELECT
        ft."id",
        ft."date",
        ft."title",
        gv."vector"                         AS vec,
        COALESCE(wf."frequency", 1)         AS freq
    FROM filtered_tokens ft
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
           ON gv."word" = ft."word"
    LEFT JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
           ON wf."word" = ft."word"
),
/* 4. explode each vector & weight by frequency^-0.4 */
weighted_vec_elements AS (
    SELECT
        w."id",
        w."date",
        w."title",
        v.index                               AS dim_idx,
        v.value::FLOAT / POWER(w.freq, 0.4)   AS weighted_val
    FROM word_vectors w,
         LATERAL FLATTEN( INPUT => w.vec ) v
),
/* 5. sum weighted components per dimension for each article */
article_raw_vec AS (
    SELECT
        "id", "date", "title", dim_idx,
        SUM( weighted_val ) AS dim_val
    FROM weighted_vec_elements
    GROUP BY "id", "date", "title", dim_idx
),
/* 6. calculate vector magnitude */
article_mag AS (
    SELECT
        "id", "date", "title",
        SQRT( SUM( POWER(dim_val, 2) ) ) AS mag
    FROM article_raw_vec
    GROUP BY "id", "date", "title"
    HAVING mag > 0
),
/* 7. normalise, round to 4 decimals, and turn into comma‑separated string */
article_vector AS (
    SELECT
        r."id",
        r."date",
        r."title",
        LISTAGG( TO_VARCHAR( ROUND( r.dim_val / m.mag , 4 ) ), ', ' )
            WITHIN GROUP ( ORDER BY r.dim_idx )  AS norm_vector
    FROM article_raw_vec r
    JOIN article_mag m
          ON r."id"   = m."id"
         AND r."date" = m."date"
         AND r."title"= m."title"
    GROUP BY r."id", r."date", r."title", m.mag
)
/* 8. final output */
SELECT
    "id",
    "date",
    "title",
    norm_vector AS normalized_article_vector
FROM article_vector;