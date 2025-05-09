WITH
/* -------------------------------------------------------------------
   1. stop-word list  (all lower-case, quoted-identifiers not required)
------------------------------------------------------------------- */
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
    ('it'),('its'),('itself'),('just'),('ll'),('m'),('ma'),('me'),('mightn'),
    ('mightnt'),('more'),('most'),('mustn'),('mustnt'),('my'),('myself'),('needn'),
    ('neednt'),('no'),('nor'),('not'),('now'),('o'),('of'),('off'),('on'),('once'),
    ('only'),('or'),('other'),('our'),('ours'),('ourselves'),('out'),('over'),('own'),
    ('re'),('s'),('same'),('shan'),('shant'),('she'),('shes'),('should'),
    ('shouldn'),('shouldnt'),('shouldve'),('so'),('some'),('such'),('t'),('than'),
    ('that'),('thatll'),('the'),('their'),('theirs'),('them'),('themselves'),('then'),
    ('there'),('these'),('they'),('this'),('those'),('through'),('to'),('too'),
    ('under'),('until'),('up'),('ve'),('very'),('was'),('wasn'),('wasnt'),('we'),
    ('were'),('weren'),('werent'),('what'),('when'),('where'),('which'),('while'),
    ('who'),('whom'),('why'),('will'),('with'),('won'),('wont'),('wouldn'),
    ('wouldnt'),('y'),('you'),('youd'),('youll'),('your'),('youre'),('yours'),
    ('yourself'),('yourselves'),('youve')
),
/* -------------------------------------------------------------------
   2. tokenise (title + abstract + body)   →   lower-case words
------------------------------------------------------------------- */
tokens AS (
  SELECT
      n."id",
      LOWER(tok.value::string) AS word
  FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
       LATERAL FLATTEN(
               INPUT => SPLIT(
                         REGEXP_REPLACE(
                             COALESCE(n."title",'') || ' ' ||
                             COALESCE(n."abstract",'') || ' ' ||
                             COALESCE(n."body",'')
                         ,'[^\\w]+',' ')
                     ,' ')
       ) tok
  WHERE tok.value IS NOT NULL
),
/* -------------------------------------------------------------------
   3. remove stop-words and empties
------------------------------------------------------------------- */
filtered_tokens AS (
  SELECT t."id", t.word
  FROM   tokens t
  LEFT  JOIN stopwords s ON t.word = s.word
  WHERE  s.word IS NULL
         AND t.word <> ''
),
/* -------------------------------------------------------------------
   4. attach GloVe vector & corpus frequency
------------------------------------------------------------------- */
word_info AS (
  SELECT
      ft."id",
      gv."vector"  AS vec,
      wf."frequency" AS freq
  FROM   filtered_tokens ft
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = ft.word
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = ft.word
),
/* -------------------------------------------------------------------
   5. weight vector elements by freq^-0.4 and explode
------------------------------------------------------------------- */
weighted_elements AS (
  SELECT
      wi."id",
      vec_elem.key::int                       AS dim,
      vec_elem.value::float / POW(wi.freq,0.4) AS wval
  FROM   word_info wi,
         LATERAL FLATTEN( INPUT => wi.vec ) vec_elem
),
/* -------------------------------------------------------------------
   6. aggregate weighted components per article
------------------------------------------------------------------- */
sum_vec AS (
  SELECT   "id", dim, SUM(wval) AS comp
  FROM     weighted_elements
  GROUP BY "id", dim
),
/* -------------------------------------------------------------------
   7. compute L2 norm of each aggregate vector
------------------------------------------------------------------- */
norms AS (
  SELECT "id",
         SQRT( SUM(comp*comp) ) AS norm
  FROM   sum_vec
  GROUP  BY "id"
  HAVING norm > 0
),
/* -------------------------------------------------------------------
   8. normalise vectors to unit length
------------------------------------------------------------------- */
normalised AS (
  SELECT s."id",
         s.dim,
         s.comp / n.norm AS norm_val
  FROM   sum_vec s
  JOIN   norms   n ON n."id" = s."id"
),
/* -------------------------------------------------------------------
   9. vector of the target article
------------------------------------------------------------------- */
target_vec AS (
  SELECT dim, norm_val
  FROM   normalised
  WHERE  "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
/* -------------------------------------------------------------------
   10. dot-product (cosine numerator) with all other articles
------------------------------------------------------------------- */
dot_products AS (
  SELECT
      n."id"                         AS article_id,
      SUM( n.norm_val * t.norm_val ) AS dot
  FROM   normalised n
  JOIN   target_vec t ON n.dim = t.dim
  WHERE  n."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
  GROUP  BY n."id"
),
/* -------------------------------------------------------------------
   11. ensure every article appears (zero similarity if no shared dims)
------------------------------------------------------------------- */
all_articles AS (
  SELECT "id" AS article_id
  FROM   norms
  WHERE  "id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
similarities AS (
  SELECT
      a.article_id,
      COALESCE(d.dot,0) AS cosine
  FROM   all_articles a
  LEFT  JOIN dot_products d ON d.article_id = a.article_id
)
/* -------------------------------------------------------------------
   12. final top-10 list
------------------------------------------------------------------- */
SELECT
    s.article_id       AS "id",
    nat."date",
    nat."title",
    ROUND(s.cosine,4)  AS cosine_similarity
FROM   similarities s
JOIN   WORD_VECTORS_US.WORD_VECTORS_US.NATURE nat
       ON nat."id" = s.article_id
ORDER  BY cosine_similarity DESC NULLS LAST
LIMIT 10;