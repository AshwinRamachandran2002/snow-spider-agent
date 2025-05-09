/*==============================================================*/
/*  Top-10 articles most similar to the given Nature article     */
/*  (optimised – aggregates word counts before flattening)       */
/*==============================================================*/
WITH stopwords AS (                               -- light stop-word list
    SELECT COLUMN1 AS word
    FROM VALUES
        ('a'),('an'),('the'),('and'),('or'),('of'),('in'),('to'),('it'),('for'),
        ('on'),('with'),('as'),('by'),('at'),('from'),('is'),('are'),('was'),
        ('were'),('be'),('been'),('this'),('that'),('these'),('those'),('i'),
        ('you'),('he'),('she'),('they'),('we'),('but'),('if'),('into'),('about'),
        ('than'),('up'),('down'),('over'),('after'),('before'),('between'),
        ('within'),('without'),('such'),('so'),('not'),('no'),('nor'),('can'),
        ('could'),('should'),('would'),('may'),('might'),('will'),('shall'),
        ('do'),('does'),('did'),('done'),('have'),('has'),('had'),('having'),
        ('which'),('who'),('whom'),('whose'),('what'),('when'),('where'),
        ('why'),('how')
),

/*--------------------------------------------------------------*/
/* 1. basic article info & cleaned text                         */
articles AS (
    SELECT
        n."id"    AS id,
        n."date"  AS date,
        n."title" AS title,
        LOWER(REGEXP_REPLACE(n."body", '[^A-Za-z ]', ' ')) AS clean_text
    FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n
),

/*--------------------------------------------------------------*/
/* 2. explode -> words (once) & remove stop-words                */
article_words AS (
    SELECT
        a.id,
        TRIM(f.value)::STRING AS word
    FROM articles a
         CROSS JOIN LATERAL FLATTEN(INPUT => SPLIT(a.clean_text,' ')) f
         LEFT JOIN stopwords s ON TRIM(f.value)::STRING = s.word
    WHERE TRIM(f.value) <> '' AND s.word IS NULL
),

/*--------------------------------------------------------------*/
/* 3. count tokens per (article, word) – greatly reduces rows    */
word_counts AS (
    SELECT id, word, COUNT(*) AS tok_cnt
    FROM article_words
    GROUP BY id, word
),

/*--------------------------------------------------------------*/
/* 4. attach word vectors & frequencies                          */
word_info AS (
    SELECT
        wc.id,
        wc.word,
        wc.tok_cnt,
        gv."vector"            AS vec,
        wf."frequency"         AS freq
    FROM word_counts                            wc
    JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"    gv ON gv."word" = wc.word
    JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf ON wf."word" = wc.word
),

/*--------------------------------------------------------------*/
/* 5. weight vectors                                             */
weighted_elems AS (
    SELECT
        wi.id,
        fl.index                                              AS idx,
        (fl.value::DOUBLE)                                     *
        (wi.tok_cnt / POWER(wi.freq, 0.4))                    AS val
    FROM word_info wi
         CROSS JOIN LATERAL FLATTEN(INPUT => wi.vec) fl
),

/*--------------------------------------------------------------*/
/* 6. aggregate per article                                      */
article_vec AS (
    SELECT
        id,
        idx,
        SUM(val) AS elem_sum
    FROM weighted_elems
    GROUP BY id, idx
),

/*--------------------------------------------------------------*/
/* 7. normalise to unit length                                   */
article_norms AS (
    SELECT id, SQRT(SUM(elem_sum*elem_sum)) AS norm
    FROM article_vec
    GROUP BY id
),
norm_elems AS (
    SELECT
        av.id,
        av.idx,
        av.elem_sum / NULLIF(an.norm,0) AS nval
    FROM article_vec av
    JOIN article_norms an ON an.id = av.id
),

/*--------------------------------------------------------------*/
/* 8. target article elements                                    */
target_elems AS (
    SELECT idx, nval AS tval
    FROM norm_elems
    WHERE id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),

/*--------------------------------------------------------------*/
/* 9. cosine similarity (dot product)                            */
cosine_scores AS (
    SELECT
        ne.id,
        SUM(ne.nval * te.tval) AS cosine_similarity
    FROM norm_elems ne
    JOIN target_elems te ON ne.idx = te.idx
    WHERE ne.id <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    GROUP BY ne.id
)

/*--------------------------------------------------------------*/
/* 10. final output                                              */
SELECT
    cs.id,
    a.date,
    a.title,
    cs.cosine_similarity
FROM cosine_scores cs
JOIN articles a ON a.id = cs.id
ORDER BY cs.cosine_similarity DESC NULLS LAST
LIMIT 10;