WITH
/* ------------------------------------------------------------------
   1. Stop‑word list
------------------------------------------------------------------*/
stop_words(word) AS (
    SELECT column1 FROM VALUES
      ('the'),('and'),('a'),('an'),('of'),('to'),('in'),('for'),
      ('on'),('with'),('that'),('by'),('from'),('as'),('is'),
      ('are'),('was'),('were'),('be'),('been'),('being'),('at'),
      ('this'),('which'),('or'),('it'),('its'),('into'),('can'),
      ('may'),('we'),('these'),('those'),('such'),('have'),('has'),
      ('had'),('not'),('but'),('they'),('their'),('about'),('more'),
      ('other'),('also'),('than'),('our'),('between'),('one'),
      ('two'),('three'),('results'),('using'),('use'),('used')
),
/* ------------------------------------------------------------------
   2. Tokenise article body, keep alphabetic tokens ≥ 3 characters
------------------------------------------------------------------*/
tokens AS (
    SELECT  n."id",
            n."date",
            n."title",
            LOWER(TRIM(f.value)) AS token
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                 REGEXP_REPLACE(
                     LOWER(COALESCE(n."body",'')),
                     '[^a-z]+', ' '),
                 ' ')
         ) f
    WHERE LENGTH(TRIM(f.value)) > 2
),
/* ------------------------------------------------------------------
   3. Remove stop‑words
------------------------------------------------------------------*/
filtered_tokens AS (
    SELECT t.*
    FROM   tokens t
    LEFT   JOIN stop_words s ON s.word = t.token
    WHERE  s.word IS NULL
),
/* ------------------------------------------------------------------
   4. Attach frequency & GloVe vector, compute weighting factor
------------------------------------------------------------------*/
token_vectors AS (
    SELECT  ft."id",
            ft."date",
            ft."title",
            gv."vector"                       AS raw_vec,
            POWER(wf."frequency", -0.4)       AS weight
    FROM   filtered_tokens ft
    JOIN   WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
           ON wf."word" = ft.token
    JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
           ON gv."word" = ft.token
),
/* ------------------------------------------------------------------
   5. Scale every component of every word vector
------------------------------------------------------------------*/
scaled_components AS (
    SELECT  tv."id",
            tv."date",
            tv."title",
            vc.index                          AS pos,
            (vc.value::FLOAT) * tv.weight     AS comp
    FROM   token_vectors tv,
           LATERAL FLATTEN(INPUT => tv.raw_vec) vc
),
/* ------------------------------------------------------------------
   6. Sum weighted components per article & dimension
------------------------------------------------------------------*/
article_pos_sums AS (
    SELECT  "id",
            "date",
            "title",
            pos,
            SUM(comp) AS sum_comp
    FROM   scaled_components
    GROUP BY "id","date","title",pos
),
/* ------------------------------------------------------------------
   7. Collect summed components into an array
------------------------------------------------------------------*/
article_vectors AS (
    SELECT  "id",
            "date",
            "title",
            ARRAY_AGG(sum_comp)
              WITHIN GROUP (ORDER BY pos) AS sum_vec
    FROM   article_pos_sums
    GROUP BY "id","date","title"
),
/* ------------------------------------------------------------------
   8. Compute vector magnitude
------------------------------------------------------------------*/
magnitudes AS (
    SELECT  av."id",
            av."date",
            av."title",
            av.sum_vec,
            SQRT(
                SUM(POWER(comp.VALUE::FLOAT,2))
            ) AS mag
    FROM   article_vectors av,
           LATERAL FLATTEN(INPUT => av.sum_vec) comp
    GROUP BY av."id",av."date",av."title",av.sum_vec
),
/* ------------------------------------------------------------------
   9. Normalise to unit length and round to 4 decimals
------------------------------------------------------------------*/
normalised AS (
    SELECT  m."id",
            m."date",
            m."title",
            ARRAY_AGG(
                ROUND( (c.VALUE::FLOAT) / NULLIF(m.mag,0) , 4)
            ) WITHIN GROUP (ORDER BY c.index) AS norm_vec
    FROM   magnitudes m,
           LATERAL FLATTEN(INPUT => m.sum_vec) c
    WHERE  m.mag IS NOT NULL AND m.mag <> 0
    GROUP BY m."id",m."date",m."title"
)
/* ------------------------------------------------------------------
   10. Final result in requested CSV‑style format
------------------------------------------------------------------*/
SELECT
    "id"                                            AS id,
    TO_CHAR("date", 'YYYY-MM-DD')                   AS date,
    "title"                                         AS title,
    ARRAY_TO_STRING(norm_vec, ', ')                 AS normalized_article_vector
FROM normalised;