/* -----------------------------------------------------------
   Returns
     1) The U.S. B2 utility patent (granted 2010‑2014) that
        receives the largest number of forward citations coming
        from applications filed within 30 days of its own filing
        date (ties broken by publication number).
     2) The most‑similar patent (according to Google embeddings)
        from the SAME filing year. If no such similar patent is
        found, the field is left blank.                         */
WITH candidate_pats AS (      -- 1. all eligible U.S. B2 utility grants
    SELECT
        p."publication_number",
        p."filing_date",
        TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD') AS filing_dt
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'
      AND p."application_kind" = 'A'          -- utility
      AND p."grant_date" BETWEEN 20100101 AND 20141231
      AND p."filing_date"      > 0
      AND TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
), citations_30d AS (         -- 2. each forward citation within 30 days
    SELECT
        cand."publication_number"                    AS cited_pub,
        citing."publication_number"                  AS citing_pub
    FROM candidate_pats               cand
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS citing
         ON TRY_TO_DATE(citing."filing_date"::STRING,'YYYYMMDD')
               BETWEEN cand.filing_dt
                   AND DATEADD(day,30,cand.filing_dt)
    ,  LATERAL FLATTEN(input => citing."citation") cit
    WHERE cit.value:"publication_number"::STRING = cand."publication_number"
      AND TRY_TO_DATE(citing."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
), citations_agg AS (         -- 3. count of such citations
    SELECT
        cited_pub AS "publication_number",
        COUNT(DISTINCT citing_pub) AS fwd_cnt_30d
    FROM citations_30d
    GROUP BY cited_pub
), fwd_cites_30d AS (         -- 4. attach zero where none found
    SELECT
        cand."publication_number",
        COALESCE(agg.fwd_cnt_30d,0) AS fwd_cnt_30d
    FROM candidate_pats cand
    LEFT JOIN citations_agg agg
           ON cand."publication_number" = agg."publication_number"
), top_pat AS (               -- 5. patent with the max count
    SELECT "publication_number"
    FROM   fwd_cites_30d
    QUALIFY ROW_NUMBER() OVER (ORDER BY fwd_cnt_30d DESC NULLS LAST,
                               "publication_number") = 1
), pat_year AS (              -- filing year of that top patent
    SELECT
        tp."publication_number" AS top_pub,
        cand."filing_date",
        YEAR(TRY_TO_DATE(cand."filing_date"::STRING,'YYYYMMDD')) AS filing_year
    FROM top_pat tp
    JOIN candidate_pats cand
          ON cand."publication_number" = tp."publication_number"
), sim_list AS (              -- Google similarity list for the top patent
    SELECT
        py.top_pub,
        sim.value:"publication_number"::STRING AS similar_pub,
        sim.index                               AS sim_rank
    FROM pat_year py
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB emb
          ON emb."publication_number" = py.top_pub
    ,  LATERAL FLATTEN(input => emb."similar") sim
), sim_with_year AS (         -- filing year of each similar patent
    SELECT
        s.top_pub,
        s.similar_pub,
        s.sim_rank,
        YEAR(TRY_TO_DATE(pub."filing_date"::STRING,'YYYYMMDD')) AS sim_filing_year
    FROM sim_list s
    LEFT JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub
           ON pub."publication_number" = s.similar_pub
    WHERE TRY_TO_DATE(pub."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
), best_sim AS (              -- first similar patent from same year
    SELECT
        swy.top_pub,
        swy.similar_pub
    FROM sim_with_year swy
    JOIN pat_year py ON py.top_pub = swy.top_pub
    WHERE swy.sim_filing_year = py.filing_year
    QUALIFY ROW_NUMBER() OVER (PARTITION BY swy.top_pub
                               ORDER BY swy.sim_rank) = 1
)
SELECT
    py.top_pub                                    AS "US_B2_PATENT_WITH_MAX_FWD_CITES_WITHIN_MONTH",
    COALESCE(bs.similar_pub,'')                   AS "MOST_SIMILAR_PATENT_SAME_YEAR"
FROM pat_year  py
LEFT JOIN best_sim bs
       ON bs.top_pub = py.top_pub;