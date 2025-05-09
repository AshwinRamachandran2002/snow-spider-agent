WITH candidate_pats AS (          -- 1.  US utility-type (B2) grants 2010-2014
    SELECT  p."publication_number",
            p."filing_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE   p."country_code" = 'US'
      AND   p."kind_code"    = 'B2'
      AND   p."grant_date" BETWEEN 20100101 AND 20141231
      AND   p."filing_date" > 0
),                                  -- 2.  Flatten every citation (any country / type)
citing_flat AS (
    SELECT  c."publication_number"                       AS "citing_pub",
            c."filing_date"                              AS "citing_file_dt",
            f.value:"publication_number"::STRING         AS "cited_pub"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS c,
            LATERAL FLATTEN( INPUT => c."citation" ) f
    WHERE   c."filing_date" > 0
),                                  -- 3.  Count forward citations within 30 days
forward_counts AS (
    SELECT  cp."publication_number",
            COUNT(*) AS "fwd_cites_30d"
    FROM    candidate_pats cp
    JOIN    citing_flat   cf
      ON    cf."cited_pub"       = cp."publication_number"
      AND   cf."citing_file_dt" BETWEEN cp."filing_date"
                                   AND     cp."filing_date" + 30
    GROUP BY cp."publication_number"
),                                  -- 4.  Pick the most-cited focal patent
top_cited AS (
    SELECT  fc."publication_number",
            fc."fwd_cites_30d",
            cp."filing_date"
    FROM    forward_counts fc
    JOIN    candidate_pats cp
      ON    cp."publication_number" = fc."publication_number"
    ORDER BY fc."fwd_cites_30d" DESC NULLS LAST,
             fc."publication_number"
    LIMIT 1
),                                  -- 5.  Flatten focal embedding
focal_vec AS (
    SELECT  tv."publication_number",
            fv.index        AS "idx",
            fv.value::FLOAT AS "val"
    FROM    top_cited tv
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
      ON    a."publication_number" = tv."publication_number",
          LATERAL FLATTEN( INPUT => a."embedding_v1" ) fv
),                                  -- 6.  Peers: all filings in same calendar year
peer_meta AS (
    SELECT  pp."publication_number"
    FROM    top_cited t
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pp
      ON    FLOOR(pp."filing_date"/10000) = FLOOR(t."filing_date"/10000)
    WHERE   pp."publication_number" <> t."publication_number"
      AND   pp."filing_date" > 0
),                                  -- 7.  Flatten each peer’s embedding
peer_vec AS (
    SELECT  pm."publication_number",
            pv.index        AS "idx",
            pv.value::FLOAT AS "val"
    FROM    peer_meta pm
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB pa
      ON    pa."publication_number" = pm."publication_number",
          LATERAL FLATTEN( INPUT => pa."embedding_v1" ) pv
),                                  -- 8.  Cosine-like dot-product similarity
similarity AS (
    SELECT  pv."publication_number"                     AS "peer_pub",
            SUM( pv."val" * fv."val" )                  AS "sim_score"
    FROM    peer_vec pv
    JOIN    focal_vec fv USING ("idx")
    GROUP BY pv."publication_number"
),                                  -- 9.  Peer with maximum similarity
most_similar AS (
    SELECT  s."peer_pub",
            s."sim_score"
    FROM    similarity s
    ORDER BY s."sim_score" DESC NULLS LAST
    LIMIT 1
)
SELECT  tc."publication_number"          AS "focal_patent",
        tc."fwd_cites_30d"               AS "forward_citations_30d",
        ms."peer_pub"                    AS "most_similar_patent",
        ms."sim_score"                   AS "similarity_score"
FROM    top_cited   tc
CROSS JOIN most_similar ms;