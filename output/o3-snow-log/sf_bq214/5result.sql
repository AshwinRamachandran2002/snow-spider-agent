/*----------------------------------------------------------
   1)  Identify US utility patents (kind B2) granted 2010-2014
       whose filing-date can be parsed to a valid DATE value.
----------------------------------------------------------*/
WITH candidate_patents AS (
    SELECT
        "publication_number",
        "filing_date",
        TRY_TO_DATE(TO_VARCHAR("filing_date"),'YYYYMMDD')  AS filing_dt
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "country_code"     = 'US'
      AND "kind_code"        = 'B2'
      AND "application_kind" = 'A'
      AND "grant_date" BETWEEN 20100101 AND 20141231
      AND "filing_date" IS NOT NULL
),
valid_candidates AS (
    SELECT *
    FROM candidate_patents
    WHERE filing_dt IS NOT NULL          -- drop rows whose date failed to parse
),

/*----------------------------------------------------------
   2)  Build table of (citing → cited) pairs with valid
       filing-dates for the citing publications.
----------------------------------------------------------*/
citing_publications AS (
    SELECT
        p."publication_number"                              AS citing_pub,
        TRY_TO_DATE(TO_VARCHAR(p."filing_date"),'YYYYMMDD') AS citing_filing_dt,
        f.value:"publication_number"::string                AS cited_pub
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") f
    WHERE p."filing_date" IS NOT NULL
      AND TRY_TO_DATE(TO_VARCHAR(p."filing_date"),'YYYYMMDD') IS NOT NULL
),

/*----------------------------------------------------------
   3)  Count forward citations arriving within 30 days
       of each candidate’s own filing-date.
----------------------------------------------------------*/
forward_counts AS (
    SELECT
        vc."publication_number",
        COUNT(*) AS forward_cites_30d
    FROM valid_candidates vc
    JOIN citing_publications ci
          ON ci.cited_pub = vc."publication_number"
         AND ci.citing_filing_dt BETWEEN vc.filing_dt
                                     AND DATEADD(day,30,vc.filing_dt)
    GROUP BY vc."publication_number"
),

/*----------------------------------------------------------
   4)  Patent with the highest such forward-citation count.
----------------------------------------------------------*/
top_candidate AS (
    SELECT "publication_number", forward_cites_30d
    FROM forward_counts
    ORDER BY forward_cites_30d DESC NULLS LAST, "publication_number"
    LIMIT 1
),

/*----------------------------------------------------------
   5)  Retrieve its embedding and filing-year.
----------------------------------------------------------*/
candidate_info AS (
    SELECT
        tc."publication_number",
        vc.filing_dt,
        YEAR(vc.filing_dt)                  AS filing_year,
        fc.forward_cites_30d,
        ae."embedding_v1"                   AS cand_emb
    FROM top_candidate tc
    JOIN valid_candidates vc  ON vc."publication_number" = tc."publication_number"
    JOIN forward_counts  fc   ON fc."publication_number" = tc."publication_number"
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
         ON ae."publication_number" = tc."publication_number"
),

/*----------------------------------------------------------
   6)  All OTHER patents filed in the same year (any kind)
       that have embeddings.
----------------------------------------------------------*/
same_year_embeddings AS (
    SELECT
        ae."publication_number",
        ae."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  ae
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
         ON p."publication_number" = ae."publication_number"
    JOIN candidate_info ci
         ON YEAR(TRY_TO_DATE(TO_VARCHAR(p."filing_date"),'YYYYMMDD')) = ci.filing_year
    WHERE ae."embedding_v1" IS NOT NULL
      AND p."publication_number" <> (SELECT "publication_number" FROM candidate_info)
      AND TRY_TO_DATE(TO_VARCHAR(p."filing_date"),'YYYYMMDD') IS NOT NULL
),

/*----------------------------------------------------------
   7)  Compute cosine-like similarity (dot-product) between
       embeddings and select the most similar patent.
----------------------------------------------------------*/
similarity_rank AS (
    SELECT
        sy."publication_number"                                   AS similar_pub,
        SUM(f1.value::float * f2.value::float)                    AS sim_score
    FROM same_year_embeddings sy
    JOIN candidate_info ci ON 1 = 1
        , LATERAL FLATTEN(input => sy."embedding_v1") f1
        , LATERAL FLATTEN(input => ci.cand_emb)      f2
    WHERE f1.index = f2.index
    GROUP BY sy."publication_number"
    ORDER BY sim_score DESC NULLS LAST
    LIMIT 1
)

/*----------------------------------------------------------
   8)  Final answer.
----------------------------------------------------------*/
SELECT
    ci."publication_number"  AS candidate_publication_number,
    ci.forward_cites_30d     AS forward_citations_within_30_days,
    sr.similar_pub           AS most_similar_publication_number_same_year,
    sr.sim_score             AS similarity_score
FROM candidate_info ci
CROSS JOIN similarity_rank sr;