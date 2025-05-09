/* ---------------------------------------------------------------
   Find articles most similar to the target one
   (id = 8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373)
   – speed-optimised: per-article we keep at most the 300
     most frequent (after stop-word removal) tokens and
     fold multiple occurrences into a single weighted entry.
-----------------------------------------------------------------*/
WITH stopwords AS (                              -- ❶ stop-word list
  SELECT column1 AS word FROM VALUES
    ('a'),('about'),('above'),('after'),('again'),('against'),('ain'),
    ('all'),('am'),('an'),('and'),('any'),('are'),('aren'),('arent'),
    ('as'),('at'),('be'),('because'),('been'),('before'),('being'),
    ('below'),('between'),('both'),('but'),('by'),('can'),('couldn'),
    ('couldnt'),('d'),('did'),('didn'),('didnt'),('do'),('does'),
    ('doesn'),('doesnt'),('doing'),('don'),('dont'),('down'),('during'),
    ('each'),('few'),('for'),('from'),('further'),('had'),('hadn'),
    ('hadnt'),('has'),('hasn'),('hasnt'),('have'),('haven'),('havent'),
    ('having'),('he'),('her'),('here'),('hers'),('herself'),('him'),
    ('himself'),('his'),('how'),('i'),('if'),('in'),('into'),('is'),
    ('isn'),('isnt'),('it'),('its'),('itself'),('just'),('ll'),('m'),
    ('ma'),('me'),('mightn'),('mightnt'),('more'),('most'),('mustn'),
    ('mustnt'),('my'),('myself'),('needn'),('neednt'),('no'),('nor'),
    ('not'),('now'),('o'),('of'),('off'),('on'),('once'),('only'),
    ('or'),('other'),('our'),('ours'),('ourselves'),('out'),('over'),
    ('own'),('re'),('s'),('same'),('shan'),('shant'),('she'),('shes'),
    ('should'),('shouldn'),('shouldnt'),('shouldve'),('so'),('some'),
    ('such'),('t'),('than'),('that'),('thatll'),('the'),('their'),
    ('theirs'),('them'),('themselves'),('then'),('there'),('these'),
    ('they'),('this'),('those'),('through'),('to'),('too'),('under'),
    ('until'),('up'),('ve'),('very'),('was'),('wasn'),('wasnt'),('we'),
    ('were'),('weren'),('werent'),('what'),('when'),('where'),('which'),
    ('while'),('who'),('whom'),('why'),('will'),('with'),('won'),
    ('wont'),('wouldn'),('wouldnt'),('y'),('you'),('youd'),('youll'),
    ('your'),('youre'),('yours'),('yourself'),('yourselves'),('youve')
),
/* ---------------------------------------------------------------
   ❷ Tokenise body text, drop stop-words, count occurrences
-----------------------------------------------------------------*/
token_counts AS (
  SELECT
      n."id"                                   AS article_id,
      LOWER(tok.value)                         AS token,
      COUNT(*)                                 AS tok_cnt
  FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n,
       LATERAL FLATTEN(
         INPUT => SPLIT(
                   REGEXP_REPLACE(LOWER(n."body"), '[^a-z0-9]+', ' '),
                   ' ')
       ) tok
  WHERE tok.value IS NOT NULL
    AND tok.value <> ''
    AND tok.value NOT IN (SELECT word FROM stopwords)
  GROUP BY article_id, token
),
/* ---------------------------------------------------------------
   ❸ Retain per-article the 300 most frequent tokens
-----------------------------------------------------------------*/
top_tokens AS (
  SELECT *
  FROM (
    SELECT
        tc.*,
        ROW_NUMBER() OVER (PARTITION BY article_id
                           ORDER BY tok_cnt DESC) AS rn
    FROM token_counts tc
  )
  WHERE rn <= 300
),
/* ---------------------------------------------------------------
   ❹ Join with GloVe vectors and global corpus frequencies
-----------------------------------------------------------------*/
token_data AS (
  SELECT
      tt.article_id                          AS id,
      gv."vector"                            AS vec,
      tt.tok_cnt                             AS tf,
      COALESCE(wf."frequency",1)             AS df          -- corpus freq
  FROM top_tokens tt
  JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS" gv
    ON gv."word" = tt.token
  LEFT JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
    ON wf."word" = tt.token
),
/* ---------------------------------------------------------------
   ❺ Weight vectors (tf / df^0.4) and explode to 100 components
-----------------------------------------------------------------*/
weighted_comp AS (
  SELECT
      td.id,
      f.index                                 AS idx,
      (f.value::FLOAT) * td.tf
      / POWER(td.df, 0.4)                     AS w_val
  FROM token_data td,
       LATERAL FLATTEN(INPUT => td.vec) f
),
/* ---------------------------------------------------------------
   ❻ Aggregate to article-level vectors  (100 components each)
-----------------------------------------------------------------*/
article_vec AS (
  SELECT
      id,
      idx,
      SUM(w_val)                              AS comp_val
  FROM weighted_comp
  GROUP BY id, idx
),
/* ---------------------------------------------------------------
   ❼ Compute vector norms and normalise
-----------------------------------------------------------------*/
norms AS (
  SELECT
      id,
      SQRT(SUM(comp_val * comp_val))          AS nrm
  FROM article_vec
  GROUP BY id
),
normalised AS (
  SELECT
      av.id,
      av.idx,
      av.comp_val / n.nrm                     AS val
  FROM article_vec av
  JOIN norms n ON n.id = av.id
  WHERE n.nrm > 0
),
/* ---------------------------------------------------------------
   ❽ Target article’s normalised vector
-----------------------------------------------------------------*/
target AS (
  SELECT idx, val
  FROM normalised
  WHERE id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
/* ---------------------------------------------------------------
   ❾ Cosine similarity = dot product with target
-----------------------------------------------------------------*/
similarities AS (
  SELECT
      a.id,
      SUM(a.val * COALESCE(t.val,0))          AS cosine_sim
  FROM normalised a
  LEFT JOIN target t
    ON t.idx = a.idx
  GROUP BY a.id
)
/* ---------------------------------------------------------------
   ❿ Return top-10 most similar (excluding the target itself)
-----------------------------------------------------------------*/
SELECT
    n."id",
    n."date",
    n."title",
    s.cosine_sim
FROM similarities s
JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n
  ON n."id" = s.id
WHERE n."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
ORDER BY s.cosine_sim DESC NULLS LAST
LIMIT 10;