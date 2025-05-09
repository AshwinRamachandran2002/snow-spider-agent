/* ----------------------------------------------------------------------
   Find the 10 articles most similar to
   8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373
   (cosine similarity of weighted‑GloVe representations)
------------------------------------------------------------------------*/
WITH
/* 1. stop‑words ---------------------------------------------------------*/
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
('they'),('this'),('those'),('through'),('to'),('too'),('under'),('until'),('up'),('ve'),('very'),
('was'),('wasn'),('wasnt'),('we'),('were'),('weren'),('werent'),('what'),('when'),('where'),
('which'),('while'),('who'),('whom'),('why'),('will'),('with'),('won'),('wont'),('wouldn'),
('wouldnt'),('y'),('you'),('youd'),('youll'),('your'),('youre'),('yours'),('yourself'),
('yourselves'),('youve')
),

/* 2. tokenize bodies, drop stop‑words, count tokens ---------------------*/
word_counts AS (   
    SELECT
        n."id"                                AS id,
        LOWER(st.VALUE::STRING)               AS word,
        COUNT(*)                              AS cnt
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL SPLIT_TO_TABLE(
                 REGEXP_REPLACE(LOWER(n."body"), '[^a-z0-9]+', ' '), ' '
         ) st
    WHERE st.VALUE IS NOT NULL
      AND st.VALUE <> ''
      AND NOT EXISTS (SELECT 1 FROM stopwords s WHERE s.word = LOWER(st.VALUE::STRING))
    GROUP BY id, word
),

/* 3. attach GloVe vectors and global frequencies ------------------------*/
wc_vec AS (
    SELECT
        wc.id,
        gv."vector"                     AS vec,
        wc.cnt                          AS cnt,
        wf."frequency"                  AS freq
    FROM word_counts wc
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = wc.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = wc.word
),

/* 4. expand each vector element & apply weighting -----------------------*/
article_dims AS (
    SELECT
        id,
        f.INDEX                          AS dim,
        (f.VALUE::FLOAT) * cnt / POWER(freq, 0.4)  AS dim_val
    FROM wc_vec,
         LATERAL FLATTEN(INPUT => vec) f
),

/* 5. aggregate weighted vectors per article -----------------------------*/
article_vec AS (
    SELECT id, dim, SUM(dim_val) AS dim_val
    FROM article_dims
    GROUP BY id, dim
),

/* 6. compute L2 norm for each article -----------------------------------*/
article_norm AS (
    SELECT id, SQRT(SUM(dim_val * dim_val)) AS norm
    FROM article_vec
    GROUP BY id
    HAVING norm > 0
),

/* 7. normalise vectors to unit length -----------------------------------*/
unit_vec AS (
    SELECT v.id, v.dim, v.dim_val / n.norm AS val
    FROM article_vec v
    JOIN article_norm n USING(id)
),

/* 8. vector of target article -------------------------------------------*/
target AS (
    SELECT dim, val AS tgt_val
    FROM unit_vec
    WHERE id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),

/* 9. cosine similarity (dot product of unit vectors) --------------------*/
scores AS (
    SELECT u.id,
           SUM(u.val * t.tgt_val) AS sim
    FROM unit_vec u
    JOIN target  t USING(dim)
    GROUP BY u.id
)

/* 10. top‑10 most similar articles --------------------------------------*/
SELECT
    s.id,
    n."date",
    n."title",
    s.sim AS cosine_similarity
FROM scores s
JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
      ON n."id" = s.id
WHERE s.id <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
ORDER BY s.sim DESC NULLS LAST, s.id
LIMIT 10;