/* ------------------------------------------------------------------
   Find the US-utility (kind B2) patent granted 2010-2014 with the
   most forward citations in the first 30 days after filing, then
   return the most-similar patent (Google-embeddings) from the same
   filing year.
----------------------------------------------------------------------*/
WITH candidate AS (               /* 1. focal-patent pool            */
    SELECT
        "publication_number",
        TRY_TO_DATE("filing_date"::STRING ,'YYYYMMDD') AS filing_dt,
        TRY_TO_DATE("grant_date" ::STRING ,'YYYYMMDD') AS grant_dt,
        "title_localized"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "country_code"     = 'US'
      AND "kind_code"        = 'B2'
      AND "application_kind" = 'A'                                   -- utility
      AND TRY_TO_DATE("grant_date"::STRING,'YYYYMMDD')
            BETWEEN '2010-01-01' AND '2014-12-31'
      AND TRY_TO_DATE("filing_date"::STRING ,'YYYYMMDD') IS NOT NULL
),
/* ------------------------------------------------------------------
   2. build cited-by table (flatten citations once)                  */
pub_cites AS (
    SELECT
        src."publication_number"                                     AS citing_pub,
        TRY_TO_DATE(src."filing_date"::STRING,'YYYYMMDD')            AS citing_filing_dt,
        cit.value:"publication_number"::STRING                       AS cited_pub
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  src,
         LATERAL FLATTEN( INPUT => src."citation")    cit
    WHERE cit.value:"publication_number" IS NOT NULL
      AND TRY_TO_DATE(src."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
),
/* ------------------------------------------------------------------
   3. forward citations within 30 days of the candidate’s filing     */
forward_cites AS (
    SELECT
        cand."publication_number"                    AS pn,
        COUNT(DISTINCT pc.citing_pub)                AS fwd_cites_1m
    FROM candidate  cand
    JOIN pub_cites  pc
          ON pc.cited_pub = cand."publication_number"
         AND pc.citing_filing_dt BETWEEN cand.filing_dt
                                     AND DATEADD('day',30,cand.filing_dt)
    GROUP BY cand."publication_number"
),
/* ------------------------------------------------------------------
   4. patent with the highest early-forward-citation count           */
top_patent AS (
    SELECT
        c."publication_number",
        c.filing_dt,
        c.grant_dt,
        c."title_localized",
        COALESCE(f.fwd_cites_1m,0) AS fwd_cites_1m
    FROM candidate c
    LEFT JOIN forward_cites f
           ON f.pn = c."publication_number"
    ORDER BY COALESCE(f.fwd_cites_1m,0) DESC NULLS LAST
    LIMIT 1
),
/* ------------------------------------------------------------------
   5. patents listed as most-similar (Google embeddings) that share
      the same filing year                                           */
similar_filtered AS (
    SELECT
        sim.value:"publication_number"::STRING           AS similar_pn,
        ROW_NUMBER() OVER (ORDER BY sim.index)           AS rn
    FROM top_patent tp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  ae
         ON ae."publication_number" = tp."publication_number"
        ,LATERAL FLATTEN( INPUT => ae."similar")  sim
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
         ON p2."publication_number" = sim.value:"publication_number"::STRING
    WHERE YEAR( TRY_TO_DATE(p2."filing_date"::STRING,'YYYYMMDD') )
              = YEAR( tp.filing_dt )
)
/* ------------------------------------------------------------------
   6. final result                                                   */
SELECT
    tp."publication_number"        AS focal_publication_number,
    tp.filing_dt                   AS focal_filing_date,
    tp.grant_dt                    AS focal_grant_date,
    tp.fwd_cites_1m                AS forward_citations_within_30_days,
    tp."title_localized"           AS focal_title_localized,
    sf.similar_pn                  AS most_similar_publication_number_same_year
FROM top_patent tp
LEFT JOIN ( SELECT similar_pn FROM similar_filtered WHERE rn = 1 ) sf
       ON 1=1;