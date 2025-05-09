/* ------------------------------------------------------------
   Build a unit-length (normalised) vector for every article in
   WORD_VECTORS_US.WORD_VECTORS_US.NATURE (Snowflake dialect).

   Steps
   1.  Tokenise article body text → alphabetic words, drop a
       small stop-word list.
   2.  Count every distinct token per article (term-frequency tf).
   3.  Join tokens to WORD_FREQUENCIES and GLOVE_VECTORS.
   4.  Weight every vector component by  tf / (global_freq ^ 0.4)
       and sum across a document.
   5.  Normalise the resulting article vector to unit length.
   ------------------------------------------------------------ */
WITH articles AS (  ---------------------------------------------------
    SELECT  "id",
            "date",
            "title",
            LOWER("body")                       AS body_text
    FROM    WORD_VECTORS_US.WORD_VECTORS_US.NATURE
    WHERE   "body" IS NOT NULL
),                                                                    
tokens AS (    -------------------------------------------------------
    /* split text into alphabetic tokens, filter simple stop-words   */
    SELECT  a."id",
            a."date",
            a."title",
            tok.value::string                     AS token
    FROM    articles a,
            LATERAL FLATTEN ( 
                    INPUT => SPLIT(
                                REGEXP_REPLACE( a.body_text
                                               ,'[^a-z]',' ' ) , -- keep letters
                                ' '                                -- split on space
                             )
            ) tok
    WHERE   tok.value IS NOT NULL
      AND   tok.value <> ''
      AND   tok.value NOT IN (  -- concise stop-word list (lower-case)
        'a','an','the','and','or','but','if','in','into','on','onto',
        'with','without','to','from','of','at','by','for','is','are',
        'was','were','be','been','being','this','that','these','those',
        'as','it','its','their','there','here','his','her','hers','our',
        'ours','your','yours','my','mine','they','them','he','she','we',
        'you','i','not','no','nor','so','than','too','very','can',
        'cannot','will','would','could','should','shall','may','might',
        'must','do','does','did','done','have','has','had','having',
        'which','who','whom','whose','what','when','where','why','how',
        'all','any','each','few','more','most','other','some','such',
        'only','own','same'
      )
),                                                                    
word_counts AS (  ----------------------------------------------------
    /* term-frequency for each token in an article                  */
    SELECT  "id",
            "date",
            "title",
            token,
            COUNT(*)                           AS tf
    FROM    tokens
    GROUP BY "id","date","title",token
),                                                                    
word_data AS (    ----------------------------------------------------
    /* attach global frequency + GloVe vector                       */
    SELECT  wc."id",
            wc."date",
            wc."title",
            wc.token,
            wc.tf,
            wf."frequency"                    AS global_freq,
            gv."vector"
    FROM    word_counts                              wc
    JOIN    WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES  wf
              ON wf."word" = wc.token
    JOIN    WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS     gv
              ON gv."word" = wc.token
),                                                                    
weighted_components AS (  -------------------------------------------
    /* flatten 300-D vector and apply weighting                     */
    SELECT  wd."id",
            wd."date",
            wd."title",
            f.index                                AS idx,
            SUM( (f.value::float)
                  * wd.tf
                  / POWER(wd.global_freq, 0.4) )   AS component
    FROM    word_data  wd,
            LATERAL FLATTEN( INPUT => wd."vector" ) f
    GROUP BY wd."id", wd."date", wd."title", f.index
),                                                                    
vector_magnitude AS (  ------------------------------------------------
    /* Euclidean norm of each raw article vector                    */
    SELECT  "id",
            SQRT( SUM( POWER(component, 2) ) )  AS mag
    FROM    weighted_components
    GROUP BY "id"
),                                                                    
normalized_components AS (  ------------------------------------------
    /* divide each component by its magnitude                       */
    SELECT  wc."id",
            wc."date",
            wc."title",
            wc.idx,
            wc.component / vm.mag                 AS norm_comp
    FROM    weighted_components wc
    JOIN    vector_magnitude   vm
          ON wc."id" = vm."id"
    WHERE   vm.mag > 0
),                                                                    
article_vectors AS (  -------------------------------------------------
    /* assemble the ordered, normalised components into an array    */
    SELECT  "id",
            "date",
            "title",
            ARRAY_AGG(norm_comp) WITHIN GROUP (ORDER BY idx)
                                                  AS normalized_vector
    FROM    normalized_components
    GROUP BY "id","date","title"
)                                                                    
SELECT  "id",
        "date",
        "title",
        normalized_vector  AS "article_vector"
FROM    article_vectors
ORDER BY "date" NULLS LAST;