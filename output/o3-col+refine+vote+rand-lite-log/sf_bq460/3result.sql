WITH
/* --------------------------------------------------- */
/* 1) list of stop-words                               */
/* --------------------------------------------------- */
stopwords(word) AS (
    SELECT column1 FROM VALUES
        ('a'),('about'),('above'),('after'),('again'),('against'),
        ('all'),('am'),('an'),('and'),('any'),('are'),('as'),('at'),
        ('be'),('because'),('been'),('before'),('being'),('below'),
        ('between'),('both'),('but'),('by'),('can'),('could'),
        ('did'),('do'),('does'),('doing'),('down'),('during'),
        ('each'),('few'),('for'),('from'),('further'),('had'),
        ('has'),('have'),('having'),('he'),('her'),('here'),
        ('hers'),('herself'),('him'),('himself'),('his'),('how'),
        ('i'),('if'),('in'),('into'),('is'),('it'),('its'),
        ('itself'),('just'),('me'),('more'),('most'),('my'),
        ('myself'),('no'),('nor'),('not'),('now'),('of'),('off'),
        ('on'),('once'),('only'),('or'),('other'),('our'),
        ('ours'),('ourselves'),('out'),('over'),('own'),('re'),
        ('s'),('same'),('she'),('should'),('so'),('some'),
        ('such'),('than'),('that'),('the'),('their'),('theirs'),
        ('them'),('themselves'),('then'),('there'),('these'),
        ('they'),('this'),('those'),('through'),('to'),('too'),
        ('under'),('until'),('up'),('very'),('was'),('we'),
        ('were'),('what'),('when'),('where'),('which'),('while'),
        ('who'),('whom'),('why'),('will'),('with'),('you'),
        ('your'),('yours'),('yourself'),('yourselves')
),

/* --------------------------------------------------- */
/* 2) tokenize bodies & drop stop-words                */
/* --------------------------------------------------- */
tokenised AS (
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(t.value)                    AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL SPLIT_TO_TABLE(
             REGEXP_REPLACE(n."body", '[^a-z0-9]+', ' '), ' '
         ) t
    WHERE t.value <> ''
      AND LOWER(t.value) NOT IN (SELECT word FROM stopwords)
),

/* --------------------------------------------------- */
/* 3) attach vector + corpus frequency                 */
/* --------------------------------------------------- */
word_info AS (
    SELECT
        tok."id",
        tok."date",
        tok."title",
        gv."vector"          AS vector,
        wf."frequency"       AS frequency
    FROM tokenised tok
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
          ON gv."word" = tok.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
          ON wf."word" = tok.word
),

/* --------------------------------------------------- */
/* 4) weight each dimension of each word               */
/* --------------------------------------------------- */
weighted_dims AS (
    SELECT
        wi."id",
        wi."date",
        wi."title",
        f.index::INT                                           AS dim,
        (f.value::FLOAT / POWER(wi.frequency, 0.4))            AS contrib
    FROM word_info wi,
         LATERAL FLATTEN(input => wi.vector) f
),

/* --------------------------------------------------- */
/* 5) sum contributions per article / dimension        */
/* --------------------------------------------------- */
article_vec AS (
    SELECT
        "id",
        "date",
        "title",
        dim,
        SUM(contrib)                              AS value
    FROM weighted_dims
    GROUP BY "id","date","title",dim
),

/* --------------------------------------------------- */
/* 6) vector norms per article                         */
/* --------------------------------------------------- */
article_norm AS (
    SELECT
        "id",
        "date",
        "title",
        SQRT(SUM(POWER(value,2)))                 AS norm
    FROM article_vec
    GROUP BY "id","date","title"
),

/* --------------------------------------------------- */
/* 7) target article’s vector & norm                   */
/* --------------------------------------------------- */
target_vec AS (
    SELECT
        av.dim,
        av.value,
        an.norm                                   AS target_norm
    FROM article_vec  av
    JOIN article_norm an ON an."id" = av."id"
    WHERE av."id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),

/* --------------------------------------------------- */
/* 8) dot-products with every other article            */
/* --------------------------------------------------- */
similarity_raw AS (
    SELECT
        av."id",
        an."date",
        an."title",
        SUM(av.value * tv.value)                  AS dot_prod,
        an.norm                                   AS norm,
        MAX(tv.target_norm)                       AS target_norm   -- same for every row
    FROM article_vec av
    JOIN target_vec   tv  ON tv.dim = av.dim
    JOIN article_norm an  ON an."id" = av."id"
    WHERE av."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    GROUP BY av."id", an."date", an."title", an.norm
),

/* --------------------------------------------------- */
/* 9) cosine similarity                                */
/* --------------------------------------------------- */
similarity AS (
    SELECT
        "id",
        "date",
        "title",
        dot_prod / (norm * target_norm)           AS cosine_similarity
    FROM similarity_raw
)

/* --------------------------------------------------- */
/* 10) top 10 most similar articles                    */
/* --------------------------------------------------- */
SELECT
    "id",
    "date",
    "title",
    cosine_similarity
FROM similarity
ORDER BY cosine_similarity DESC NULLS LAST
LIMIT 10;