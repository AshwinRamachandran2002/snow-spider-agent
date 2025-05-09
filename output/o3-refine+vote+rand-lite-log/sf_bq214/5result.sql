/* -----------------------------------------------------------
   1)  Identify US utility patents (kind B2) granted 2010‑2014
       with a valid filing date.
   2)  Count forward citations whose own filing dates fall
       within 30 days of the focal filing date.
   3)  Keep the patent with the largest such count.
   4)  From Google‑provided “similar” list, pick first patent
       filed in the same year as the focal one.
----------------------------------------------------------- */
WITH "US_B2_2010_2014" AS (
    SELECT
        p."publication_number",
        TRY_TO_DATE(p."filing_date"::TEXT , 'YYYYMMDD')  AS filing_dt
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'
      AND p."application_kind" = 'A'
      AND p."grant_date" BETWEEN 20100101 AND 20141231
      AND TRY_TO_DATE(p."filing_date"::TEXT , 'YYYYMMDD') IS NOT NULL
),

"FWD_CIT_30D" AS (
    SELECT
        u."publication_number",
        COUNT(*) AS fwd_cits_30d
    FROM  "US_B2_2010_2014"              u
    JOIN  PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB emb
          ON emb."publication_number" = u."publication_number",
          LATERAL FLATTEN( INPUT => emb."cited_by") cb
    JOIN  PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cit
          ON cit."publication_number" = cb.value:"publication_number"::TEXT
    WHERE TRY_TO_DATE(cit."filing_date"::TEXT,'YYYYMMDD') IS NOT NULL
      AND DATEDIFF(
              'day',
              u.filing_dt,
              TRY_TO_DATE(cit."filing_date"::TEXT,'YYYYMMDD')
          ) BETWEEN 0 AND 30
    GROUP BY u."publication_number"
),

"BEST_PATENT" AS (
    SELECT
        u."publication_number",
        u.filing_dt,
        COALESCE(f.fwd_cits_30d, 0) AS fwd_cits_30d
    FROM "US_B2_2010_2014" u
    LEFT JOIN "FWD_CIT_30D" f USING ("publication_number")
    ORDER BY fwd_cits_30d DESC NULLS LAST, u."publication_number"
    LIMIT 1
),

"SIMILAR_CANDIDATES" AS (
    SELECT
        bp."publication_number"                      AS focal_pub,
        bp.filing_dt                                 AS focal_filing_dt,
        sim.index                                    AS sim_rank,
        sim.value:"publication_number"::TEXT         AS similar_pub
    FROM "BEST_PATENT" bp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB emb
          ON emb."publication_number" = bp."publication_number",
         LATERAL FLATTEN( INPUT => emb."similar") sim
),

"SIMILAR_SAME_YEAR" AS (
    SELECT
        sc.similar_pub
    FROM  "SIMILAR_CANDIDATES" sc
    JOIN  PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS sp
          ON sp."publication_number" = sc.similar_pub
    WHERE YEAR( TRY_TO_DATE(sp."filing_date"::TEXT,'YYYYMMDD') ) =
          YEAR(sc.focal_filing_dt)
    ORDER BY sc.sim_rank
    LIMIT 1
)

SELECT
    bp."publication_number"  AS "FOCAL_PUBLICATION_NUMBER",
    bp.fwd_cits_30d          AS "FORWARD_CITATIONS_WITHIN_30D",
    ss.similar_pub           AS "MOST_SIMILAR_PUBLICATION_SAME_YEAR"
FROM "BEST_PATENT" bp
LEFT JOIN "SIMILAR_SAME_YEAR" ss ON TRUE;