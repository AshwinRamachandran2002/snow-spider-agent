/* --------------------------------------------------------------------------
   Snowflake-compatible query
   -------------------------------------------------------------------------- */
WITH candidate_pats AS (      -- US-B2 patents granted 2010-2014
    SELECT  p."publication_number"            AS PUBLICATION_NUMBER,
            p."filing_date"                   AS FILING_DATE,
            TO_DATE(TO_VARCHAR(p."filing_date"), 'YYYYMMDD') AS FILE_DT
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE   p."country_code" = 'US'
      AND   p."kind_code"    = 'B2'
      AND   p."grant_date" BETWEEN 20100101 AND 20141231
      AND   p."filing_date"  > 0
),
fwd_30d AS (                  -- forward citations within 30 days
    SELECT   c.PUBLICATION_NUMBER                          AS PUBLICATION_NUMBER,
             COUNT(DISTINCT cp."publication_number")       AS FWD_CNT
    FROM     candidate_pats c
    JOIN     PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cp
             ON cp."filing_date" > 0
    ,        LATERAL FLATTEN( input => cp."citation" ) f
    WHERE    f.value:"publication_number"::STRING = c.PUBLICATION_NUMBER
      AND    TO_DATE(TO_VARCHAR(cp."filing_date"), 'YYYYMMDD')
              BETWEEN c.FILE_DT
                  AND DATEADD(day, 30, c.FILE_DT)
    GROUP BY c.PUBLICATION_NUMBER
),
top_cand AS (                 -- patent with max early forward cites
    SELECT  PUBLICATION_NUMBER,
            FWD_CNT
    FROM    fwd_30d
    QUALIFY ROW_NUMBER() OVER (ORDER BY FWD_CNT DESC NULLS LAST) = 1
),
cand_info AS (                -- metadata of focal patent
    SELECT  p."publication_number"                            AS FOCAL_PUB,
            p."filing_date"                                   AS FILING_DATE,
            SUBSTR(TO_VARCHAR(p."filing_date"),1,4)           AS FILING_YEAR,
            tc.FWD_CNT
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    top_cand tc
            ON tc.PUBLICATION_NUMBER = p."publication_number"
),
cand_emb AS (                 -- embedding of focal patent
    SELECT  fe.index        AS IDX,
            fe.value::FLOAT AS VAL
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae,
            LATERAL FLATTEN( input => ae."embedding_v1" ) fe,
            cand_info ci
    WHERE   ae."publication_number" = ci.FOCAL_PUB
),
same_year_pubs AS (           -- other publications same filing year
    SELECT  p."publication_number" AS OTHER_PUB
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p,
            cand_info ci
    WHERE   SUBSTR(TO_VARCHAR(p."filing_date"),1,4) = ci.FILING_YEAR
      AND   p."publication_number" <> ci.FOCAL_PUB
),
sim_scores AS (               -- similarity (dot-product)
    SELECT   op.OTHER_PUB,
             SUM(ce.VAL * ofe.value::FLOAT) AS DOTPROD
    FROM     same_year_pubs op
    JOIN     PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB oae
             ON oae."publication_number" = op.OTHER_PUB
    ,        LATERAL FLATTEN( input => oae."embedding_v1" ) ofe
    JOIN     cand_emb ce
             ON ce.IDX = ofe.index
    GROUP BY op.OTHER_PUB
    ORDER BY DOTPROD DESC NULLS LAST
    LIMIT 1
)
SELECT  ci.FOCAL_PUB                         AS focal_publication,
        ci.FILING_YEAR                       AS filing_year,
        ci.FWD_CNT                           AS forward_cites_first_30d,
        ss.OTHER_PUB                         AS most_similar_publication,
        ss.DOTPROD                           AS similarity_score
FROM    cand_info ci
CROSS JOIN sim_scores ss;