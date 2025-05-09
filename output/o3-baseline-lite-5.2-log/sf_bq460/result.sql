WITH
stopwords AS (  -- a  list of stop‑words to exclude
    SELECT COLUMN1 AS word FROM VALUES
    ('a'),('about'),('above'),('after'),('again'),('against'),('ain'),('all'),('am'),('an'),
    ('and'),('any'),('are'),('aren'),('arent'),('as'),('at'),('be'),('because'),('been'),
    ('before'),('being'),('below'),('between'),('both'),('but'),('by'),('can'),('couldn'),
    ('couldnt'),('d'),('did'),('didn'),('didnt'),('do'),('does'),('doesn'),('doesnt'),
    ('doing'),('don'),('dont'),('down'),('during'),('each'),('few'),('for'),('from'),
    ('further'),('had'),('hadn'),('hadnt'),('has'),('hasn'),('hasnt'),('have'),('haven'),
    ('havent'),('having'),('he'),('her'),('here'),('hers'),('herself'),('him'),('himself'),
    ('his'),('how'),('i'),('if'),('in'),('into'),('is'),('isn'),('isnt'),('it'),('its'),
    ('itself'),('just'),('ll'),('m'),('ma'),('me'),('mightn'),('mightnt'),('more'),
    ('most'),('mustn'),('mustnt'),('my'),('myself'),('needn'),('neednt'),('no'),('nor'),
    ('not'),('now'),('o'),('of'),('off'),('on'),('once'),('only'),('or'),('other'),
    ('our'),('ours'),('ourselves'),('out'),('over'),('own'),('re'),('s'),('same'),
    ('shan'),('shant'),('she'),('shes'),('should'),('shouldn'),('shouldnt'),('shouldve'),
    ('so'),('some'),('such'),('t'),('than'),('that'),('thatll'),('the'),('their'),
    ('theirs'),('them'),('themselves'),('then'),('there'),('these'),('they'),('this'),
    ('those'),('through'),('to'),('too'),('under'),('until'),('up'),('ve'),('very'),
    ('was'),('wasn'),('wasnt'),('we'),('were'),('weren'),('werent'),('what'),('when'),
    ('where'),('which'),('while'),('who'),('whom'),('why'),('will'),('with'),('won'),
    ('wont'),('wouldn'),('wouldnt'),('y'),('you'),('youd'),('youll'),('your'),('youre'),
    ('yours'),('yourself'),('yourselves'),('youve')
),
tokenised AS (  -- tokenise body text and drop stop‑words
    SELECT
        n."id",
        LOWER(f.value::STRING) AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                        REGEXP_REPLACE(
                          REGEXP_REPLACE(LOWER(n."body"), '’|''s(\W)', '\\1'),
                          '[^0-9a-z]+', ' '
                        ),
                        ' '
                      )
         ) f
    WHERE f.value IS NOT NULL
      AND f.value <> ''
      AND LOWER(f.value::STRING) NOT IN (SELECT word FROM stopwords)
),
word_vectors AS (  -- attach GloVe vectors and corpus frequency
    SELECT
        t."id",
        gv."vector"    AS glove_vec,
        wf."frequency" AS freq
    FROM tokenised t
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = t.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = t.word
),
weighted_dims AS ( -- explode vectors and apply frequency weighting
    SELECT
        wv."id"                              AS id,
        f.index::INT                         AS idx,        -- dimension (0‑299)
        (f.value::FLOAT) / POWER(wv.freq, 0.4) AS val       -- weighted component
    FROM word_vectors wv,
         LATERAL FLATTEN(INPUT => wv.glove_vec) f
),
article_dims AS ( -- sum weighted components per article & dimension
    SELECT
        id,
        idx,
        SUM(val) AS vec_val
    FROM weighted_dims
    GROUP BY id, idx
),
norms AS (        -- L2 norm of every article vector, keep non‑zero
    SELECT
        id,
        SQRT(SUM(vec_val * vec_val)) AS norm
    FROM article_dims
    GROUP BY id
    HAVING norm > 0
),
unit_dims AS (    -- normalise each article vector to unit length
    SELECT
        ad.id,
        ad.idx,
        ad.vec_val / n.norm AS u_val
    FROM article_dims ad
    JOIN norms       n ON n.id = ad.id
),
target_unit AS (  -- the normalised vector of the reference article
    SELECT idx, u_val
    FROM unit_dims
    WHERE id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
dot_products AS ( -- cosine similarity = dot product of two unit vectors
    SELECT
        a.id,
        SUM(a.u_val * t.u_val) AS cos_sim
    FROM unit_dims a
    JOIN target_unit t ON a.idx = t.idx
    WHERE a.id <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    GROUP BY a.id
),
results AS (
    SELECT
        dp.id,
        n."date",
        n."title",
        dp.cos_sim
    FROM dot_products dp
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
      ON n."id" = dp.id
    WHERE dp.cos_sim IS NOT NULL
)
SELECT
    id,
    "date",
    "title",
    ROUND(cos_sim, 4) AS cosine_similarity
FROM results
ORDER BY cosine_similarity DESC NULLS LAST, id
LIMIT 10;