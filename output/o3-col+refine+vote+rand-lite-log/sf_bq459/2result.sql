/*--------------------------------------------------------------------
  Return the 10 Nature articles whose bodies are most similar (cosine)
  to the query:
  “Epigenetics and cerebral organoids: promising directions in autism
   spectrum disorders”
--------------------------------------------------------------------*/
WITH
/*----------- 1.  Query vector ---------------------------------------*/
q_tokens AS (          -- tokenise & lowercase
    SELECT LOWER(st.value)::STRING AS token
    FROM ( SELECT
             'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders'
               AS qtxt ) q
    CROSS JOIN LATERAL SPLIT_TO_TABLE(
                          REGEXP_REPLACE(q.qtxt,'[^A-Za-z ]',' ')
                        , ' ') st
    WHERE st.value IS NOT NULL AND st.value <> ''
),
q_vec_components AS (   -- weight each token vector
    SELECT
        gv_el.index                                   AS dim,
        gv_el.value::FLOAT /
        POWER( COALESCE(wf."frequency",1) , 0.4 )     AS w_val
    FROM q_tokens qt
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = qt.token
    LEFT JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = qt.token
    CROSS JOIN LATERAL FLATTEN(INPUT => gv."vector") gv_el
),
q_sum  AS ( SELECT dim, SUM(w_val) AS val FROM q_vec_components GROUP BY dim ),
q_norm AS ( SELECT SQRT(SUM(val*val)) AS n FROM q_sum ),
q_unit AS ( SELECT dim, val/n AS unit_val FROM q_sum, q_norm ),

/*----------- 2.  Candidate articles (simple keyword pre-filter) -----*/
cand_articles AS (
    SELECT "id","date","title","body"
    FROM   WORD_VECTORS_US.WORD_VECTORS_US."NATURE"
    WHERE  "body" ILIKE '%epigenetic%'
        OR "body" ILIKE '%cerebral%'
        OR "body" ILIKE '%organoid%'
        OR "body" ILIKE '%autism%'
),

/*----------- 3.  Token counts per candidate article -----------------*/
art_token_counts AS (
    SELECT
        ca."id",
        ca."date",
        ca."title",
        LOWER(st.value)::STRING         AS token,
        COUNT(*)                        AS tk_cnt
    FROM   cand_articles ca
    CROSS JOIN LATERAL SPLIT_TO_TABLE(
                       REGEXP_REPLACE(ca."body", '[^A-Za-z ]',' ')
                     , ' ') st
    WHERE  st.value IS NOT NULL AND st.value <> ''
    GROUP BY ca."id", ca."date", ca."title", LOWER(st.value)
),

/*----------- 4.  Weight for each (article, token) -------------------*/
art_word_wt AS (
    SELECT
        atc."id",
        atc."date",
        atc."title",
        atc.token,
        atc.tk_cnt /
        POWER( COALESCE(wf."frequency",1) , 0.4 )     AS wt
    FROM art_token_counts atc
    LEFT JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
           ON wf."word" = atc.token
),

/*----------- 5.  Pre-compute per-word metrics -----------------------*/
vocab AS ( SELECT DISTINCT token AS word FROM art_word_wt ),
word_feats AS (
    SELECT
        gv."word",
        SUM( gv_el.value::FLOAT * COALESCE(qu.unit_val,0) )  AS dot_q,
        SUM( POWER(gv_el.value::FLOAT,2) )                   AS l2_sq
    FROM   vocab vb
    JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
           ON gv."word" = vb.word
    CROSS JOIN LATERAL FLATTEN(INPUT => gv."vector") gv_el
    LEFT  JOIN q_unit qu
           ON qu.dim = gv_el.index
    GROUP BY gv."word"
),

/*----------- 6.  Article-level dot product & norm -------------------*/
art_scores AS (
    SELECT
        aw."id",
        aw."date",
        aw."title",
        SUM( aw.wt * wf.dot_q )             AS dot_prod,
        SUM( POWER(aw.wt,2) * wf.l2_sq )    AS norm_sq
    FROM   art_word_wt aw
    JOIN   word_feats wf
           ON wf."word" = aw.token
    GROUP BY aw."id", aw."date", aw."title"
)

/*----------- 7.  Top-10 by cosine similarity ------------------------*/
SELECT
    "id",
    "date",
    "title",
    dot_prod / SQRT(norm_sq)   AS cosine_similarity
FROM   art_scores
WHERE  norm_sq > 0
ORDER BY cosine_similarity DESC NULLS LAST
LIMIT 10;