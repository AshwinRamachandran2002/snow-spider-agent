WITH
/* -------------------------------------------------------------- */
/* basic English stop-word list                                   */
stopwords(w) AS (
    SELECT column1 FROM VALUES
        ('a'),('about'),('above'),('after'),('again'),('against'),
        ('all'),('am'),('an'),('and'),('any'),('are'),('as'),('at'),
        ('be'),('because'),('been'),('before'),('being'),('below'),
        ('between'),('both'),('but'),('by'),('could'),('did'),('do'),
        ('does'),('doing'),('down'),('during'),('each'),('few'),
        ('for'),('from'),('further'),('had'),('has'),('have'),
        ('having'),('he'),('her'),('here'),('hers'),('herself'),
        ('him'),('himself'),('his'),('how'),('i'),('if'),('in'),
        ('into'),('is'),('it'),('its'),('itself'),('just'),('me'),
        ('more'),('most'),('my'),('myself'),('no'),('nor'),('not'),
        ('now'),('of'),('off'),('on'),('once'),('only'),('or'),
        ('other'),('our'),('ours'),('ourselves'),('out'),('over'),
        ('own'),('same'),('she'),('should'),('so'),('some'),('such'),
        ('than'),('that'),('the'),('their'),('theirs'),('them'),
        ('themselves'),('then'),('there'),('these'),('they'),
        ('this'),('those'),('through'),('to'),('too'),('under'),
        ('until'),('up'),('very'),('was'),('we'),('were'),('what'),
        ('when'),('where'),('which'),('while'),('who'),('whom'),
        ('why'),('with'),('you'),('your'),('yours'),('yourself'),
        ('yourselves')
),
/* -------------------------------------------------------------- */
/* tokenise article bodies                                         */
tokens AS (
    SELECT  n."id"                                    AS article_id,
            tok.value::TEXT                           AS word
    FROM    WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
            ,LATERAL FLATTEN(
                 INPUT => SPLIT(
                             REGEXP_REPLACE( LOWER(n."body"),
                                              '[^a-z]+',' '),
                             ' ')
            ) tok
    WHERE   tok.value IS NOT NULL
      AND   tok.value <> ''
),
/* -------------------------------------------------------------- */
/* count each non-stopword in every article                        */
word_counts AS (
    SELECT  t.article_id,
            t.word,
            COUNT(*)                         AS cnt
    FROM    tokens t
            LEFT JOIN stopwords sw ON t.word = sw.w
    WHERE   sw.w IS NULL
    GROUP BY t.article_id, t.word
),
/* -------------------------------------------------------------- */
/* build frequency-weighted vector components                      */
components AS (
    SELECT  wc.article_id,
            vec.index                        AS idx,
            SUM( vec.value::FLOAT
                 * wc.cnt
                 / POWER(wf."frequency", 0.4) )  AS component
    FROM    word_counts wc
            JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
                 ON gv."word" = wc.word
            JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
                 ON wf."word" = wc.word
            ,LATERAL FLATTEN(INPUT => gv."vector") vec
    GROUP BY wc.article_id, vec.index
),
/* -------------------------------------------------------------- */
/* ℓ2 norms of aggregate vectors                                   */
norms AS (
    SELECT  article_id,
            SQRT(SUM(component*component))  AS norm
    FROM    components
    GROUP BY article_id
),
/* -------------------------------------------------------------- */
/* normalise to unit length                                        */
normalized AS (
    SELECT  c.article_id,
            c.idx,
            c.component / n.norm            AS value
    FROM    components c
            JOIN norms n USING (article_id)
),
/* -------------------------------------------------------------- */
/* vector of reference article                                     */
target AS (
    SELECT idx, value
    FROM   normalized
    WHERE  article_id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
/* -------------------------------------------------------------- */
/* cosine similarities                                             */
similarity AS (
    SELECT  nrm.article_id,
            SUM(nrm.value * tgt.value)      AS sim
    FROM    normalized nrm
            JOIN target tgt USING(idx)
    WHERE   nrm.article_id <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    GROUP BY nrm.article_id
)
/* -------------------------------------------------------------- */
SELECT  s.article_id                       AS "id",
        nat."date",
        nat."title",
        ROUND(s.sim,4)                     AS "cosine_similarity"
FROM    similarity  s
        JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE nat
          ON nat."id" = s.article_id
ORDER BY "cosine_similarity" DESC NULLS LAST
LIMIT 10;