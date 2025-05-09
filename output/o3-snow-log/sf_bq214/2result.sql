/* 1) pick the U.S. utility patent (kind B2, grant 2010-2014) that receives the
      highest number of forward-citations filed within 30 days after its own
      filing date                                                       
   2) among all patents filed in the same calendar year, find the one whose
      abstract/claims/description embedding has the highest dot-product
      similarity with that focal patent                                  */

WITH candidate_patents AS (   -------------------------------------------------
    SELECT  p."publication_number",
            p."filing_date" ,                       -- YYYYMMDD  (NUMBER)
            p."grant_date"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
    WHERE   p."country_code"     = 'US'
        AND p."kind_code"        = 'B2'             -- granted utility patent
        AND p."application_kind" = 'A'
        AND p."grant_date" BETWEEN 20100101 AND 20141231
        AND p."filing_date"      > 0
), citations AS (            ---------------------------------------------------
    /* every citing-cited pair that contains a publication_number */
    SELECT  citing."publication_number"                       AS "citing_pub",
            citing."filing_date"                              AS "citing_filing",
            cited.value:"publication_number"::STRING          AS "cited_pub"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  citing,
            LATERAL FLATTEN( INPUT => citing."citation")      cited
    WHERE   cited.value:"publication_number" IS NOT NULL
), forward_cnt AS (         ---------------------------------------------------
    /* forward citations received ≤ 30 days after own filing               */
    SELECT  cp."publication_number"                            AS "target_pub",
            COUNT(DISTINCT c."citing_pub")                     AS "fwd_cites_30d"
    FROM    candidate_patents   cp
    LEFT JOIN citations        c
           ON  c."cited_pub" = cp."publication_number"
           AND c."citing_filing" BETWEEN cp."filing_date"
                                     AND cp."filing_date" + 30
    GROUP BY cp."publication_number"
), top_candidate AS (       ----------------------------------------------------
    /* keep the single patent with the largest such forward-citation count */
    SELECT  fc."target_pub",
            fc."fwd_cites_30d",
            p."filing_date",
            FLOOR(p."filing_date"/10000)                      AS "filing_year"
    FROM    forward_cnt               fc
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
           ON p."publication_number" = fc."target_pub"
    QUALIFY ROW_NUMBER() OVER (ORDER BY fc."fwd_cites_30d" DESC NULLS LAST,
                                         fc."target_pub") = 1
), candidate_emb AS (       ----------------------------------------------------
    SELECT  tc."target_pub",
            a."embedding_v1"       AS "cand_emb",
            tc."filing_year"
    FROM    top_candidate  tc
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  a
           ON a."publication_number" = tc."target_pub"
), peers AS (               ----------------------------------------------------
    /* all other patents (any type/kind) filed in the same calendar year   */
    SELECT  p."publication_number",
            a."embedding_v1"       AS "peer_emb"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS     p
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB      a
           ON a."publication_number" = p."publication_number"
    JOIN    candidate_emb  ce
           ON FLOOR(p."filing_date"/10000) = ce."filing_year"
    WHERE   p."publication_number" <> ce."target_pub"
      AND   p."filing_date" > 0
), dot_products AS (        ----------------------------------------------------
    /* dot-product between focal embedding and every peer embedding        */
    SELECT  ce."target_pub",
            pe."publication_number"             AS "peer_pub",
            SUM( ce_val.value::FLOAT * pe_val.value::FLOAT )  AS "dot_product"
    FROM    candidate_emb                 ce,
            LATERAL FLATTEN(INPUT => ce."cand_emb")  ce_val,
            peers                         pe,
            LATERAL FLATTEN(INPUT => pe."peer_emb")  pe_val
    WHERE   ce_val.index = pe_val.index                -- align vector element
    GROUP BY ce."target_pub", pe."publication_number"
), most_similar AS (        ----------------------------------------------------
    SELECT  dp."target_pub",
            dp."peer_pub"            AS "most_similar_pub",
            dp."dot_product"
    FROM    dot_products  dp
    QUALIFY ROW_NUMBER() OVER (ORDER BY dp."dot_product" DESC NULLS LAST) = 1
)  ---------------------------------------------------------------------------
SELECT  tc."target_pub"            AS "most_cited_patent",
        tc."fwd_cites_30d"         AS "forward_cites_within_30d",
        ms."most_similar_pub",
        ms."dot_product"           AS "similarity_score"
FROM    top_candidate  tc
JOIN    most_similar  ms
       ON ms."target_pub" = tc."target_pub";