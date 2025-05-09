/* -----------------------------------------------------------
   Top‑10 Nature articles most similar to the target article
   (ID = 8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373)
   ----------------------------------------------------------- */
WITH stopwords(w) AS (      -- minimal stop‑word list (hard‑coded)
    SELECT COLUMN1 FROM VALUES
    ('a'),('about'),('above'),('after'),('again'),('against'),('ain'),('all'),('am'),
    ('an'),('and'),('any'),('are'),('aren'),('arent'),('as'),('at'),('be'),('because'),
    ('been'),('before'),('being'),('below'),('between'),('both'),('but'),('by'),('can'),
    ('couldn'),('couldnt'),('d'),('did'),('didn'),('didnt'),('do'),('does'),('doesn'),
    ('doesnt'),('doing'),('don'),('dont'),('down'),('during'),('each'),('few'),('for'),
    ('from'),('further'),('had'),('hadn'),('hadnt'),('has'),('hasn'),('hasnt'),('have'),
    ('haven'),('havent'),('having'),('he'),('her'),('here'),('hers'),('herself'),
    ('him'),('himself'),('his'),('how'),('i'),('if'),('in'),('into'),('is'),('isn'),
    ('isnt'),('it'),('its'),('itself'),('just'),('ll'),('m'),('ma'),('me'),('mightn'),
    ('mightnt'),('more'),('most'),('mustn'),('mustnt'),('my'),('myself'),('needn'),
    ('neednt'),('no'),('nor'),('not'),('now'),('o'),('of'),('off'),('on'),('once'),
    ('only'),('or'),('other'),('our'),('ours'),('ourselves'),('out'),('over'),('own'),
    ('re'),('s'),('same'),('shan'),('shant'),('she'),('shes'),('should'),('shouldn'),
    ('shouldnt'),('shouldve'),('so'),('some'),('such'),('t'),('than'),('that'),
    ('thatll'),('the'),('their'),('theirs'),('them'),('themselves'),('then'),('there'),
    ('these'),('they'),('this'),('those'),('through'),('to'),('too'),('under'),
    ('until'),('up'),('ve'),('very'),('was'),('wasn'),('wasnt'),('we'),('were'),
    ('weren'),('werent'),('what'),('when'),('where'),('which'),('while'),('who'),
    ('whom'),('why'),('will'),('with'),('won'),('wont'),('wouldn'),('wouldnt'),('y'),
    ('you'),('youd'),('youll'),('your'),('youre'),('yours'),('yourself'),
    ('yourselves'),('youve')
),
article_tokens AS (         -- tokenize, lowercase, remove stop‑words
    SELECT
        n."id"                               AS article_id,
        LOWER(t.value::STRING)               AS word
    FROM   "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n,
           LATERAL FLATTEN(
               INPUT => SPLIT(
                           REGEXP_REPLACE(LOWER(n."body"), '[^0-9a-z]+', ' '),
                           ' ')
           ) t
    WHERE t.value IS NOT NULL
),
article_tokens_filtered AS (
    SELECT at.*
    FROM   article_tokens at
    LEFT JOIN stopwords s ON at.word = s.w
    WHERE s.w IS NULL            -- exclude stop‑words
      AND at.word <> ''
),
token_vectors AS (           -- attach vectors and weight = 1 / freq^0.4
    SELECT
        at.article_id,
        gv."vector"                            AS vec,
        POWER(wf."frequency", -0.4)            AS weight
    FROM   article_tokens_filtered             at
    JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS" gv
           ON gv."word" = at.word
    JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
           ON wf."word" = at.word
),
weighted_elements AS (       -- scale each vector element
    SELECT
        tv.article_id,
        f.index                              AS dim,
        f.value::FLOAT * tv.weight           AS val
    FROM   token_vectors tv,
           LATERAL FLATTEN(INPUT => tv.vec) f
),
summed_elements AS (         -- sum per article & dimension
    SELECT
        article_id,
        dim,
        SUM(val)                          AS val
    FROM   weighted_elements
    GROUP BY article_id, dim
),
article_norms AS (           -- L2 norm for each article vector
    SELECT
        article_id,
        SQRT(SUM(POWER(val, 2)))          AS norm
    FROM   summed_elements
    GROUP BY article_id
),
target_vec AS (              -- vector of reference article
    SELECT dim, val
    FROM   summed_elements
    WHERE  article_id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
dot_products AS (            -- dot product with reference
    SELECT
        se.article_id,
        SUM(se.val * tv.val)                AS dot
    FROM   summed_elements se
    JOIN   target_vec    tv  ON tv.dim = se.dim
    GROUP BY se.article_id
),
similarities AS (            -- cosine similarity
    SELECT
        dp.article_id,
        dp.dot / (an.norm * ref.norm)       AS cosine_similarity
    FROM   dot_products  dp
    JOIN   article_norms an  ON an.article_id = dp.article_id
    CROSS JOIN (
        SELECT norm
        FROM   article_norms
        WHERE  article_id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    ) ref
    WHERE  dp.article_id <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
)
SELECT
    n."id",
    n."date",
    n."title",
    ROUND(s.cosine_similarity, 6) AS cosine_similarity
FROM   similarities s
JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n
       ON n."id" = s.article_id
ORDER BY s.cosine_similarity DESC NULLS LAST, n."id"
LIMIT 10;