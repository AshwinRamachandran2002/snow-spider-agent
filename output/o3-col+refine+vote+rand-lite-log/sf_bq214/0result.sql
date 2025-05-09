/* -----------------------------------------------------------
   1.  US utility-patent grants (kind-code “B2”) published 2010-2014
   2.  Pick the patent that receives the most forward citations
      within ~100 days of its own filing date
   3.  From Google’s “similar” list choose the single patent
      with the highest similarity score, preferring matches
      from the same filing year when available
------------------------------------------------------------*/
WITH candidate AS (       -- focal-patent universe
    SELECT  "publication_number",
            "filing_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE   "country_code"     = 'US'
      AND   "kind_code"        = 'B2'
      AND   "application_kind" = 'A'
      AND   "publication_date" BETWEEN 20100101 AND 20141231
      AND   "filing_date"      > 0
),
cite_edges AS (           -- (citing → cited) edges with citing filing-date
    SELECT  citer."publication_number"                       AS "citing_pub",
            citer."filing_date"                              AS "citing_filing",
            cited.value:"publication_number"::STRING         AS "cited_pub"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS citer
    CROSS JOIN LATERAL FLATTEN(INPUT => citer."citation") cited
    WHERE   cited.value:"publication_number" IS NOT NULL
      AND   citer."filing_date" > 0
),
forward_cnt AS (          -- forward citations within 100 days
    SELECT  cand."publication_number",
            COUNT(*) AS "early_forward_cnt"
    FROM    candidate cand
    JOIN    cite_edges ce
           ON ce."cited_pub" = cand."publication_number"
          AND ce."citing_filing" BETWEEN cand."filing_date"
                                    AND cand."filing_date" + 100
    GROUP BY cand."publication_number"
),
top_patent AS (           -- best-cited patent
    SELECT  cand."publication_number",
            cand."filing_date",
            COALESCE(fc."early_forward_cnt",0) AS "fwd100"
    FROM    candidate cand
    LEFT  JOIN forward_cnt fc
           ON fc."publication_number" = cand."publication_number"
    ORDER BY "fwd100" DESC NULLS LAST
    LIMIT 1
),
similar_scored AS (       -- explode Google “similar” list
    SELECT  tp."publication_number"                AS "focal_pub",
            sim.value:"publication_number"::STRING AS "similar_pub",
            sim.value:"score"::FLOAT               AS "sim_score",
            pub."filing_date"                      AS "sim_filing_date",
            tp."filing_date"                       AS "focal_filing_date"
    FROM    top_patent tp
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB emb
           ON emb."publication_number" = tp."publication_number"
    CROSS JOIN LATERAL FLATTEN(INPUT => emb."similar") sim
    LEFT JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub
           ON pub."publication_number" = sim.value:"publication_number"::STRING
),
ranked_similar AS (       -- flag same-year matches
    SELECT  *,
            CASE
                WHEN "sim_filing_date" > 0
                     AND CAST("sim_filing_date"/10000 AS INT)
                         = CAST("focal_filing_date"/10000 AS INT)
                THEN 1 ELSE 0
            END AS "same_year_flag"
    FROM    similar_scored
),
best_similar AS (         -- choose best match
    SELECT  *
    FROM    ranked_similar
    ORDER BY "same_year_flag"        DESC,
             COALESCE("sim_score",-1) DESC,
             "similar_pub"
    LIMIT 1
)
SELECT  tp."publication_number"  AS "focal_publication_number",
        tp."filing_date"         AS "focal_filing_date",
        bs."similar_pub"         AS "most_similar_publication_number",
        bs."sim_filing_date"     AS "similar_filing_date",
        bs."sim_score"           AS "similarity_score"
FROM    top_patent tp
JOIN    best_similar bs
      ON bs."focal_pub" = tp."publication_number";