WITH
/* ------------------------------------------------------------------
1. Stop‑word list
------------------------------------------------------------------ */
stopwords(word) AS (
  SELECT column1 FROM VALUES
    ('a'),('about'),('above'),('after'),('again'),('against'),('ain'),('all'),('am'),
    ('an'),('and'),('any'),('are'),('aren'),('arent'),('as'),('at'),('be'),('because'),
    ('been'),('before'),('being'),('below'),('between'),('both'),('but'),('by'),('can'),
    ('couldn'),('couldnt'),('d'),('did'),('didn'),('didnt'),('do'),('does'),('doesn'),
    ('doesnt'),('doing'),('don'),('dont'),('down'),('during'),('each'),('few'),('for'),
    ('from'),('further'),('had'),('hadn'),('hadnt'),('has'),('hasn'),('hasnt'),('have'),
    ('haven'),('havent'),('having'),('he'),('her'),('here'),('hers'),('herself'),('him'),
    ('himself'),('his'),('how'),('i'),('if'),('in'),('into'),('is'),('isn'),('isnt'),
    ('it'),('its'),('itself'),('just'),('ll'),('m'),('ma'),('me'),('mightn'),('mightnt'),
    ('more'),('most'),('mustn'),('mustnt'),('my'),('myself'),('needn'),('neednt'),('no'),
    ('nor'),('not'),('now'),('o'),('of'),('off'),('on'),('once'),('only'),('or'),
    ('other'),('our'),('ours'),('ourselves'),('out'),('over'),('own'),('re'),('s'),
    ('same'),('shan'),('shant'),('she'),('shes'),('should'),('shouldn'),('shouldnt'),
    ('shouldve'),('so'),('some'),('such'),('t'),('than'),('that'),('thatll'),('the'),
    ('their'),('theirs'),('them'),('themselves'),('then'),('there'),('these'),('they'),
    ('this'),('those'),('through'),('to'),('too'),('under'),('until'),('up'),('ve'),
    ('very'),('was'),('wasn'),('wasnt'),('we'),('were'),('weren'),('werent'),('what'),
    ('when'),('where'),('which'),('while'),('who'),('whom'),('why'),('will'),('with'),
    ('won'),('wont'),('wouldn'),('wouldnt'),('y'),('you'),('youd'),('youll'),('your'),
    ('youre'),('yours'),('yourself'),('yourselves'),('youve')
),
consts AS (SELECT '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'::TEXT AS ref_id),

/* ------------------------------------------------------------------
2. Tokenise article bodies and remove stop‑words
------------------------------------------------------------------ */
tokens AS (
  SELECT  n."id"                              AS article_id,
          LOWER(tok.value)                    AS word
  FROM    "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n,
          LATERAL SPLIT_TO_TABLE(
            REGEXP_REPLACE(n."body", '’|''s(\W)', '\\1'),  -- strip possessive/apostrophes
            '[^[:alnum:]]+'                                -- split on non‑alphanumerics
          ) tok
  WHERE   tok.value IS NOT NULL
    AND   TRIM(tok.value) <> ''
),
filtered_tokens AS (
  SELECT article_id, word
  FROM   tokens
  WHERE  word NOT IN (SELECT word FROM stopwords)
),

/* ------------------------------------------------------------------
3. Retrieve GloVe vectors & word frequencies, apply weight
------------------------------------------------------------------ */
token_vectors AS (
  SELECT  ft.article_id,
          f.index                                                AS dim,
          f.value::FLOAT / NULLIF( POW(wf."frequency", 0.4), 0 ) AS val
  FROM    filtered_tokens ft
  JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"    gv
         ON gv."word" = ft.word
  JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
         ON wf."word" = ft.word
  ,      LATERAL FLATTEN( INPUT => PARSE_JSON(gv."vector") ) f
),

/* ------------------------------------------------------------------
4. Aggregate weighted vectors per article & dimension
------------------------------------------------------------------ */
agg_vectors AS (
  SELECT  article_id,
          dim,
          SUM(val) AS val
  FROM    token_vectors
  GROUP BY article_id, dim
),

/* ------------------------------------------------------------------
5. Compute article‑wise L2 norms
------------------------------------------------------------------ */
article_norms AS (
  SELECT  article_id,
          SQRT( SUM( POWER(val, 2) ) ) AS norm
  FROM    agg_vectors
  GROUP BY article_id
),

/* ------------------------------------------------------------------
6. Normalise vectors to unit length
------------------------------------------------------------------ */
norm_vectors AS (
  SELECT  a.article_id,
          a.dim,
          a.val / n.norm AS norm_val
  FROM    agg_vectors     a
  JOIN    article_norms   n  ON n.article_id = a.article_id
  WHERE   n.norm <> 0
),

/* ------------------------------------------------------------------
7. Reference article normalised vector
------------------------------------------------------------------ */
ref_vec AS (
  SELECT  dim,
          norm_val AS ref_val
  FROM    norm_vectors, consts
  WHERE   article_id = ref_id
),

/* ------------------------------------------------------------------
8. Cosine similarity with reference (0 when ref vector missing)
------------------------------------------------------------------ */
similarities AS (
  SELECT  nv.article_id         AS id,
          SUM( nv.norm_val * COALESCE(rv.ref_val, 0) ) AS cosine_sim
  FROM    norm_vectors nv
  LEFT JOIN ref_vec    rv
         ON rv.dim = nv.dim
  CROSS JOIN consts
  WHERE   nv.article_id <> consts.ref_id
  GROUP BY nv.article_id
),

/* ------------------------------------------------------------------
9. Ensure every other article appears even if it had no tokens
------------------------------------------------------------------ */
all_articles AS (
  SELECT  n."id" AS id,
          n."date",
          n."title"
  FROM    "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n
  CROSS JOIN consts
  WHERE   n."id" <> consts.ref_id
),

meta AS (
  SELECT  a.id,
          a."date",
          a."title",
          COALESCE(s.cosine_sim, 0) AS cosine_sim
  FROM    all_articles a
  LEFT JOIN similarities s ON s.id = a.id
)

/* ------------------------------------------------------------------
10. Return top‑10 most similar articles
------------------------------------------------------------------ */
SELECT      id,
            "date",
            "title",
            cosine_sim
FROM        meta
ORDER BY    cosine_sim DESC NULLS LAST,
            id
LIMIT       10;