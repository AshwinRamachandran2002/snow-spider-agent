/*  ---------------------------------------------------------------
    Top-10 Nature articles most similar to a given reference paper
    (Snowflake SQL – speed-optimised: token-counts first, THEN
     vector explosion; avoids blowing up on every word occurrence)
-----------------------------------------------------------------*/
WITH stopwords AS (                     -- stop-word list
    SELECT COLUMN1 AS stop FROM VALUES
        ('a'),('about'),('above'),('after'),('again'),('against'),('all'),('am'),('an'),('and'),('any'),
        ('are'),('as'),('at'),('be'),('been'),('before'),('being'),('below'),('between'),('both'),('but'),
        ('by'),('can'),('could'),('did'),('do'),('does'),('doing'),('down'),('during'),('each'),('few'),
        ('for'),('from'),('further'),('had'),('has'),('have'),('having'),('he'),('her'),('here'),('hers'),
        ('herself'),('him'),('himself'),('his'),('how'),('i'),('if'),('in'),('into'),('is'),('it'),('its'),
        ('itself'),('just'),('more'),('most'),('my'),('myself'),('no'),('nor'),('not'),('now'),('of'),
        ('off'),('on'),('once'),('only'),('or'),('other'),('our'),('ours'),('ourselves'),('out'),('over'),
        ('own'),('s'),('same'),('she'),('should'),('so'),('some'),('such'),('t'),('than'),('that'),('the'),
        ('their'),('theirs'),('them'),('themselves'),('then'),('there'),('these'),('they'),('this'),
        ('those'),('through'),('to'),('too'),('under'),('until'),('up'),('very'),('was'),('we'),('were'),
        ('what'),('when'),('where'),('which'),('while'),('who'),('whom'),('why'),('will'),('with'),
        ('you'),('your'),('yours'),('yourself'),('yourselves')
),
/*---------------------------------------------------------------
  1) TOKEN COUNTS PER ARTICLE  (1 row per token, not per occurrence)
-----------------------------------------------------------------*/
token_counts AS (
    SELECT
        n."id"                                        AS article_id,
        LOWER(tok.value::STRING)                      AS token,
        COUNT(*)                                      AS tok_cnt
    FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n
    ,    LATERAL FLATTEN(
             input => SPLIT(
                        REGEXP_REPLACE(LOWER(n."body"), '[^a-z0-9]+', ' '),
                        ' ')
         ) tok
    WHERE tok.value::STRING <> ''
      AND NOT EXISTS ( SELECT 1
                       FROM   stopwords s
                       WHERE  s.stop = LOWER(tok.value::STRING) )
    GROUP BY article_id, token
),
/*---------------------------------------------------------------
  2) KEEP TOKENS THAT HAVE BOTH VECTOR & CORPUS FREQUENCY
-----------------------------------------------------------------*/
valid_tokens AS (
    SELECT tc.article_id,
           tc.token,
           tc.tok_cnt,
           g."vector"          AS vec,
           wf."frequency"      AS corpus_freq
    FROM   token_counts tc
    JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"       g
           ON LOWER(tc.token) = LOWER(g."word")
    JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES"    wf
           ON LOWER(tc.token) = LOWER(wf."word")
),
/*---------------------------------------------------------------
  3) BUILD AGGREGATE VECTOR PER ARTICLE (dim-wise sum)
-----------------------------------------------------------------*/
agg_vectors AS (
    SELECT
        vt.article_id,
        gv.index                                 AS dim,
        SUM( (gv.value::FLOAT) *
             vt.tok_cnt /
             POWER(vt.corpus_freq, 0.4) )        AS agg_val
    FROM   valid_tokens vt
    ,      LATERAL FLATTEN(input => vt.vec) gv          -- explode 100-D vector
    GROUP  BY vt.article_id, gv.index
),
/*---------------------------------------------------------------
  4) VECTOR MAGNITUDES  (skip zero vectors)
-----------------------------------------------------------------*/
magnitudes AS (
    SELECT article_id,
           SQRT( SUM( POWER(agg_val,2) ) ) AS mag
    FROM   agg_vectors
    GROUP  BY article_id
    HAVING mag > 0
),
/*---------------------------------------------------------------
  5) NORMALISE
-----------------------------------------------------------------*/
norm_vectors AS (
    SELECT a.article_id,
           a.dim,
           a.agg_val / m.mag AS norm_val
    FROM   agg_vectors a
    JOIN   magnitudes  m  ON a.article_id = m.article_id
),
/*---------------------------------------------------------------
  6) REFERENCE ARTICLE VECTOR
-----------------------------------------------------------------*/
reference AS (
    SELECT dim, norm_val AS ref_val
    FROM   norm_vectors
    WHERE  article_id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
/*---------------------------------------------------------------
  7) COSINE SIMILARITY  (dot product of unit vectors)
-----------------------------------------------------------------*/
similarities AS (
    SELECT n.article_id,
           SUM(n.norm_val * r.ref_val) AS cosine_similarity
    FROM   norm_vectors n
    JOIN   reference    r  ON n.dim = r.dim
    GROUP  BY n.article_id
),
/*---------------------------------------------------------------
  8) TOP-10 MOST SIMILAR  (exclude the reference itself)
-----------------------------------------------------------------*/
top10 AS (
    SELECT  s.article_id,
            nat."date",
            nat."title",
            s.cosine_similarity
    FROM    similarities s
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" nat
            ON s.article_id = nat."id"
    WHERE   s.article_id <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    ORDER BY s.cosine_similarity DESC NULLS LAST
    LIMIT   10
)
SELECT *
FROM   top10;