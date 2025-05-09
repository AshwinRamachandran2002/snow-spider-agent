WITH citemap AS (                      -- (citing  ,  cited) pairs
    SELECT
        citing."publication_number"                        AS citing_pub,
        cited.value:"publication_number"::STRING           AS cited_pub
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  citing,
           LATERAL FLATTEN(INPUT => citing."citation") cited
    WHERE  cited.value:"publication_number" IS NOT NULL
),
focal_counts AS (                     -- forward-citations within ±31 days of filing
    SELECT
        cand."publication_number"                         AS focal_pub,
        cand."filing_date"                                AS focal_filing_date,
        COUNT(DISTINCT cm.citing_pub)                     AS fwd_cite_31d
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  cand
    LEFT  JOIN citemap  cm
           ON cm.cited_pub  = cand."publication_number"
    LEFT  JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  citing
           ON citing."publication_number" = cm.citing_pub
    WHERE  cand."country_code"      = 'US'
      AND  cand."kind_code"         = 'B2'
      AND  cand."application_kind"  = 'A'
      AND  cand."grant_date" BETWEEN 20100101 AND 20141231
      AND  cand."filing_date"  IS NOT NULL
      AND  citing."filing_date" IS NOT NULL
      AND  ABS(cand."filing_date" - citing."filing_date") <= 31
    GROUP BY
        cand."publication_number",
        cand."filing_date"
),
focal AS (                            -- patent with the MOST early forward citations
    SELECT
        focal_pub,
        fwd_cite_31d,
        FLOOR(focal_filing_date/10000)                    AS filing_year
    FROM   focal_counts
    ORDER BY fwd_cite_31d DESC NULLS LAST, focal_pub
    LIMIT 1
),
focal_emb AS (                        -- embedding for that patent
    SELECT
        a."publication_number"        AS focal_pub,
        a."embedding_v1"
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    JOIN   focal f
           ON f.focal_pub = a."publication_number"
),
peers AS (                            -- all other patents filed in SAME year
    SELECT
        a."publication_number",
        a."embedding_v1"
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB        a
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS       p
           ON p."publication_number" = a."publication_number"
    JOIN   focal f
           ON FLOOR(p."filing_date"/10000) = f.filing_year
    WHERE  a."publication_number" <> f.focal_pub
),
dot_scores AS (                       -- similarity (dot product) to focal embedding
    SELECT
        peers."publication_number"                    AS peer_pub,
        SUM(fe.value::FLOAT * pe.value::FLOAT)        AS dot_score
    FROM   focal_emb,
           LATERAL FLATTEN(INPUT => focal_emb."embedding_v1") fe,
           peers,
           LATERAL FLATTEN(INPUT => peers."embedding_v1")  pe
    WHERE  fe.index = pe.index
    GROUP BY peers."publication_number"
    ORDER BY dot_score DESC NULLS LAST
    LIMIT 1
)
SELECT
    f.focal_pub                             AS "focal_patent",
    f.fwd_cite_31d                          AS "forward_cites_within_31d",
    d.peer_pub                              AS "most_similar_patent_same_year",
    d.dot_score                             AS "similarity_dot_product"
FROM   focal f
CROSS  JOIN dot_scores d;