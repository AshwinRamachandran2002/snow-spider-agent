/* ------------------------------------------------------------ */
/*  Cosine-similarity of every Nature article to a reference    */
/*  (Snowflake-SQL version that avoids the lateral-join error)  */
/* ------------------------------------------------------------ */
WITH
/* 0.  reference article ID ----------------------------------- */
ref_id AS (
  SELECT '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373' AS ref_id
),

/* 0a. stop-word list ---------------------------------------- */
stopwords(word) AS (
  SELECT COLUMN1 FROM VALUES
  ('a'),('about'),('above'),('after'),('again'),('against'),('ain'),('all'),('am'),('an'),('and'),
  ('any'),('are'),('aren'),('arent'),('as'),('at'),('be'),('because'),('been'),('before'),('being'),
  ('below'),('between'),('both'),('but'),('by'),('can'),('couldn'),('couldnt'),('d'),('did'),
  ('didn'),('didnt'),('do'),('does'),('doesn'),('doesnt'),('doing'),('don'),('dont'),('down'),
  ('during'),('each'),('few'),('for'),('from'),('further'),('had'),('hadn'),('hadnt'),('has'),
  ('hasn'),('hasnt'),('have'),('haven'),('havent'),('having'),('he'),('her'),('here'),('hers'),
  ('herself'),('him'),('himself'),('his'),('how'),('i'),('if'),('in'),('into'),('is'),('isn'),
  ('isnt'),('it'),('its'),('itself'),('just'),('ll'),('m'),('ma'),('me'),('mightn'),('mightnt'),
  ('more'),('most'),('mustn'),('mustnt'),('my'),('myself'),('needn'),('neednt'),('no'),('nor'),
  ('not'),('now'),('o'),('of'),('off'),('on'),('once'),('only'),('or'),('other'),('our'),('ours'),
  ('ourselves'),('out'),('over'),('own'),('re'),('s'),('same'),('shan'),('shant'),('she'),('shes'),
  ('should'),('shouldn'),('shouldnt'),('shouldve'),('so'),('some'),('such'),('t'),('than'),('that'),
  ('thatll'),('the'),('their'),('theirs'),('them'),('themselves'),('then'),('there'),('these'),
  ('they'),('this'),('those'),('through'),('to'),('too'),('under'),('until'),('up'),('ve'),
  ('very'),('was'),('wasn'),('wasnt'),('we'),('were'),('weren'),('werent'),('what'),('when'),
  ('where'),('which'),('while'),('who'),('whom'),('why'),('will'),('with'),('won'),('wont'),
  ('wouldn'),('wouldnt'),('y'),('you'),('youd'),('youll'),('your'),('youre'),('yours'),
  ('yourself'),('yourselves'),('youve')
),

/* 1.  article-token rows (only words with vectors & frequency) */
tokens AS (
  SELECT
      n."id"                                              AS article_id,
      gv."vector"                                         AS vec,
      wf."frequency"                                      AS freq
  FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
  /* explode the article body into individual words */
  CROSS JOIN LATERAL FLATTEN(
                INPUT => SPLIT(
                           REGEXP_REPLACE(LOWER(n."body"), '[^0-9a-z ]', ' '),
                           ' '
                         )
             ) tok
  /* remove stop-words */
  LEFT  JOIN stopwords sw
         ON LOWER(tok.value)::STRING = sw.word
  /* attach GloVe vector and global frequency */
  LEFT  JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS      gv
         ON gv."word" = tok.value::STRING
  LEFT  JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES   wf
         ON wf."word" = tok.value::STRING
  WHERE tok.value IS NOT NULL
    AND tok.value <> ''
    AND sw.word IS NULL
    AND gv."vector" IS NOT NULL
    AND wf."frequency" IS NOT NULL
),

/* 2.  weighted-component sums per article ------------------- */
components AS (
  SELECT
      article_id,
      idx.index                                  AS position,
      SUM( idx.value::FLOAT / POWER(freq, 0.4) ) AS comp_sum
  FROM tokens
  CROSS JOIN LATERAL FLATTEN(input => vec) idx           -- explode 100-D vector
  GROUP BY article_id, position
),

/* 3.  vector norms per article ----------------------------- */
norms AS (
  SELECT
      article_id,
      SQRT( SUM(comp_sum * comp_sum) ) AS norm
  FROM components
  GROUP BY article_id
),

/* reference article data ----------------------------------- */
ref_components AS (
  SELECT position, comp_sum
  FROM   components
  WHERE  article_id = (SELECT ref_id FROM ref_id)
),
ref_norm AS (
  SELECT norm AS ref_norm
  FROM   norms
  WHERE  article_id = (SELECT ref_id FROM ref_id)
),

/* 4.  dot-product of every article with the reference ------- */
dot_products AS (
  SELECT
      a.article_id,
      SUM( a.comp_sum * r.comp_sum ) AS dot
  FROM components         a
  JOIN ref_components     r
    ON a.position = r.position
  GROUP BY a.article_id
),

/* 5.  cosine similarity ------------------------------------ */
cosines AS (
  SELECT
      d.article_id,
      d.dot / ( n.norm * (SELECT ref_norm FROM ref_norm) ) AS cosine_sim
  FROM dot_products d
  JOIN norms       n  ON n.article_id = d.article_id
  WHERE n.norm > 0
)

/* 6.  final top-10 most similar articles ------------------- */
SELECT
    art."id",
    art."date",
    art."title",
    c.cosine_sim
FROM cosines                           c
JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE art
  ON art."id" = c.article_id
JOIN ref_id r
WHERE c.article_id <> r.ref_id               -- exclude the query article itself
ORDER BY c.cosine_sim DESC NULLS LAST
LIMIT 10;