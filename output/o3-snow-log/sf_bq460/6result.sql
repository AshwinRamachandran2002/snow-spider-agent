WITH tokenised AS (  ----------------------------------------------------------------
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(TRIM(tok.VALUE::STRING))                                   AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                 REGEXP_REPLACE(LOWER(n."body"), '[^a-z0-9 ]', ' '),
                 ' ')
         ) tok
),                                                                           -- remove stop-words
filtered AS (
    SELECT *
    FROM   tokenised
    WHERE  word <> ''
      AND  word NOT IN
           ('a','an','the','and','or','but','if','on','in','with','is','to','of','for',
            'by','at','from','up','out','into','over','after','under','above','below',
            'about','before','between','again','further','then','once','here','there',
            'when','where','why','how','all','any','both','each','few','more','most',
            'other','some','such','no','nor','not','only','own','same','so','than',
            'too','very','can','will','just','don','should','now')
),                                                                           -- count each word once
token_counts AS (
    SELECT
        "id","date","title",
        word,
        COUNT(*)                                            AS cnt
    FROM   filtered
    GROUP  BY "id","date","title", word
),                                                                           -- join vectors & frequency
word_vecs AS (
    SELECT
        tc."id",
        tc."date",
        tc."title",
        gv."vector",
        tc.cnt,
        wf."frequency"
    FROM   token_counts tc
    JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv  ON gv."word" = tc.word
    JOIN   WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf  ON wf."word" = tc.word
),                                                                           -- explode vector, weight
components AS (
    SELECT
        w."id",
        w."date",
        w."title",
        vf.index                                            AS idx,
        vf.value::FLOAT * w.cnt / POWER(w."frequency",0.4)  AS comp
    FROM   word_vecs w,
           LATERAL FLATTEN(INPUT => w."vector")             vf
),                                                                           -- sum per dimension
article_vec AS (
    SELECT
        "id","date","title",
        idx,
        SUM(comp)                                           AS comp
    FROM   components
    GROUP BY "id","date","title", idx
),                                                                           -- article vector norm
article_norm AS (
    SELECT
        "id",
        SQRT(SUM(comp*comp))                                AS norm
    FROM   article_vec
    GROUP BY "id"
),                                                                           -- normalised components
normed AS (
    SELECT
        v."id",
        v."date",
        v."title",
        v.idx,
        CASE WHEN n.norm = 0 THEN 0 ELSE v.comp / n.norm END AS ncomp
    FROM   article_vec v
    JOIN   article_norm n ON n."id" = v."id"
),                                                                           -- target article comps
target AS (
    SELECT idx, ncomp
    FROM   normed
    WHERE  "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),                                                                           -- cosine similarity
cosine AS (
    SELECT
        n."id",
        n."date",
        n."title",
        SUM(n.ncomp * t.ncomp)                               AS cosine_similarity
    FROM   normed n
    JOIN   target t ON t.idx = n.idx
    WHERE  n."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    GROUP  BY n."id", n."date", n."title"
)
SELECT
    "id",
    "date",
    "title",
    cosine_similarity
FROM   cosine
ORDER  BY cosine_similarity DESC NULLS LAST
LIMIT  10;