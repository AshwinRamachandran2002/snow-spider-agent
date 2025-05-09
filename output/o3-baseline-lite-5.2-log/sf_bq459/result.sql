WITH  /* ---------------- stop‑word list ---------------- */
stopwords(word) AS (
    SELECT column1 FROM VALUES
        ('a'),('about'),('above'),('after'),('again'),('against'),('all'),('am'),
        ('an'),('and'),('any'),('are'),('as'),('at'),
        ('be'),('because'),('been'),('before'),('being'),('below'),('between'),
        ('both'),('but'),('by'),
        ('could'),
        ('did'),('do'),('does'),('doing'),('down'),('during'),
        ('each'),
        ('few'),('for'),('from'),('further'),
        ('had'),('has'),('have'),('having'),('he'),('her'),('here'),('hers'),
        ('herself'),('him'),('himself'),('his'),('how'),
        ('i'),('if'),('in'),('into'),('is'),('it'),('its'),('itself'),
        ('just'),
        ('me'),('more'),('most'),('my'),('myself'),
        ('no'),('nor'),('not'),('now'),
        ('of'),('off'),('on'),('once'),('only'),('or'),('other'),('our'),
        ('ours'),('ourselves'),('out'),('over'),('own'),
        ('same'),('she'),('should'),('so'),('some'),('such'),
        ('than'),('that'),('the'),('their'),('theirs'),('them'),
        ('themselves'),('then'),('there'),('these'),('they'),('this'),
        ('those'),('through'),('to'),('too'),
        ('under'),('until'),('up'),
        ('very'),
        ('was'),('we'),('were'),('what'),('when'),('where'),('which'),('while'),
        ('who'),('whom'),('why'),('with'),
        ('you'),('your'),('yours'),('yourself'),('yourselves')
),
/* ---------------- tokenise every article body ---------------- */
article_tokens AS (
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(
            REGEXP_REPLACE(n."body", '[^A-Za-z0-9 ]', ' ')
        )                        AS cleaned_body
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
),
article_words AS (
    /* explode words */
    SELECT
        at."id",
        at."date",
        at."title",
        TRIM(w.value::string) AS word
    FROM article_tokens at,
         LATERAL FLATTEN( INPUT => SPLIT(at.cleaned_body,' ') ) w
    WHERE TRIM(w.value::string) <> ''
),
/* remove stop‑words and keep words present in both helper tables */
filtered_article_words AS (
    SELECT aw.*
    FROM article_words aw
    LEFT JOIN stopwords s      ON s.word = aw.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES  wf ON wf."word" = aw.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS     gv ON gv."word" = aw.word
    WHERE s.word IS NULL
),
/* bring in frequency & glove vector */
word_details AS (
    SELECT
        faw."id",
        faw."date",
        faw."title",
        faw.word,
        wf."frequency"                        AS freq,
        gv."vector"                           AS vec
    FROM filtered_article_words faw
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = faw.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = faw.word
),
/* weight each token vector and sum per dimension (per article) */
article_dim_sums AS (
    SELECT
        wd."id",
        wd."date",
        wd."title",
        fv.index                                      AS dim,
        SUM( fv.value::float / POWER(wd.freq ,0.4) )  AS dim_sum
    FROM word_details wd,
         LATERAL FLATTEN( INPUT => wd.vec ) fv
    GROUP BY wd."id", wd."date", wd."title", fv.index
),
article_norm AS (
    SELECT "id",
           SQRT( SUM( POWER(dim_sum,2) ) ) AS norm
    FROM article_dim_sums
    GROUP BY "id"
),
article_unit AS (
    SELECT
        ads."id",
        ads."date",
        ads."title",
        ads.dim,
        ads.dim_sum / an.norm AS val
    FROM article_dim_sums ads
    JOIN article_norm     an ON an."id" = ads."id"
    WHERE an.norm > 0
),
/* ------------------   build the query vector   ------------------ */
query_tokens AS (
    SELECT LOWER(
               REGEXP_REPLACE(
                   'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',
                   '[^A-Za-z0-9 ]',' '
               )
           ) AS q_clean
),
query_words AS (
    SELECT TRIM(f.value::string) AS word
    FROM query_tokens q,
         LATERAL FLATTEN( INPUT => SPLIT(q.q_clean,' ') ) f
    WHERE TRIM(f.value::string) <> ''
),
query_filtered AS (
    SELECT qw.word
    FROM query_words qw
    LEFT JOIN stopwords s ON s.word = qw.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = qw.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = qw.word
    WHERE s.word IS NULL
),
query_details AS (
    SELECT
        qf.word,
        wf."frequency" AS freq,
        gv."vector"    AS vec
    FROM query_filtered qf
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = qf.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = qf.word
),
query_dim_sums AS (
    SELECT
        fv.index                         AS dim,
        SUM( fv.value::float / POWER(qd.freq,0.4) ) AS dim_sum
    FROM query_details qd,
         LATERAL FLATTEN( INPUT => qd.vec ) fv
    GROUP BY fv.index
),
query_norm AS (
    SELECT SQRT( SUM( POWER(dim_sum,2) ) ) AS norm
    FROM query_dim_sums
),
query_unit AS (
    SELECT
        qds.dim,
        qds.dim_sum / qn.norm AS val
    FROM query_dim_sums qds
    CROSS JOIN query_norm qn
    WHERE qn.norm > 0
),
/* ------------------ cosine similarity ------------------ */
similarities AS (
    SELECT
        au."id",
        au."date",
        au."title",
        SUM( au.val * qu.val ) AS similarity
    FROM article_unit au
    JOIN query_unit  qu ON qu.dim = au.dim
    GROUP BY au."id", au."date", au."title"
)
SELECT
    "id",
    "date",
    "title",
    similarity
FROM similarities
ORDER BY similarity DESC NULLS LAST, "id"
LIMIT 10;