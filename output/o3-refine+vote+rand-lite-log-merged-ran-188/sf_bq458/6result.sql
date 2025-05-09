/* ===============================================================
   Build a length-normalised vector for every Nature article
   – tokenise text, drop stop-words
   – weight each word’s GloVe vector by
         (#occurrences  /  corpus_frequency^0.4)
   – sum per component, normalise to unit length
================================================================= */

/* ---------------- stop-word list -------------------------------- */
WITH stop_words(word) AS (
    SELECT COLUMN1 FROM VALUES
        ('the'),('of'),('and'),('in'),('to'),('a'),('is'),('was'),('were'),
        ('with'),('for'),('on'),('that'),('by'),('an'),('as'),('at'),
        ('from'),('it'),('this'),('be'),('are'),('or'),('which'),('we'),
        ('has'),('had'),('have'),('but'),('not'),('can'),('also'),('than'),
        ('these'),('those'),('their'),('its'),('into'),('may'),('such'),
        ('other'),('more'),('less'),('been'),('our'),('using'),('use'),
        ('used'),('over'),('between'),('both'),('all')
),

/* ---------------- word counts per article ----------------------- */
token_counts AS (       -- (#occurrences of every non-stop word in each article)
    SELECT
        n."id",
        n."date",
        n."title",
        tok.VALUE::STRING      AS word,
        COUNT(*)               AS word_count
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
         , LATERAL SPLIT_TO_TABLE(
               REGEXP_REPLACE(LOWER(n."body"), '[^a-z ]', ' '),
               ' '
           ) tok
    WHERE tok.VALUE IS NOT NULL
      AND tok.VALUE <> ''
      AND tok.VALUE NOT IN (SELECT word FROM stop_words)
    GROUP BY n."id", n."date", n."title", tok.VALUE
),

/* ---------------- attach corpus frequency & GloVe vector -------- */
word_info AS (
    SELECT
        tc."id",
        tc."date",
        tc."title",
        gv."vector"          AS glove_vector,
        wf."frequency"       AS corpus_freq,
        tc.word_count
    FROM token_counts                                         tc
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON tc.word = wf."word"
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS     gv
         ON tc.word = gv."word"
),

/* ---------------- weighted component sums per article ----------- */
component_sums AS (
    SELECT
        wi."id",
        wi."date",
        wi."title",
        vec."INDEX"                                            AS idx,
        SUM(  (vec.VALUE::FLOAT)
              * wi.word_count
              / POWER(wi.corpus_freq, 0.4) )                   AS comp_sum
    FROM word_info wi
         , LATERAL FLATTEN(INPUT => wi.glove_vector) vec
    GROUP BY wi."id", wi."date", wi."title", vec."INDEX"
),

/* ---------------- magnitude of each raw article vector ---------- */
magnitudes AS (
    SELECT
        "id",
        SQRT(SUM(comp_sum * comp_sum)) AS mag
    FROM component_sums
    GROUP BY "id"
),

/* ---------------- normalise each component ---------------------- */
normalized_components AS (
    SELECT
        cs."id",
        cs."date",
        cs."title",
        cs.idx,
        cs.comp_sum / m.mag                 AS comp_norm
    FROM component_sums cs
    JOIN magnitudes  m  ON cs."id" = m."id"
    WHERE m.mag > 0
),

/* ---------------- assemble ordered arrays of components --------- */
article_vectors AS (
    SELECT
        "id",
        "date",
        "title",
        ARRAY_AGG(comp_norm) WITHIN GROUP (ORDER BY idx) AS article_vector
    FROM normalized_components
    GROUP BY "id", "date", "title"
)

/* ---------------- final output ---------------------------------- */
SELECT
    "id",
    "date",
    "title",
    article_vector
FROM article_vectors;