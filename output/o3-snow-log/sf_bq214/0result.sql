/* 1. U.S. utility patents (kind-code B2) granted 2010-2014
   2. Count forward citations received within 30 days of filing
   3. Keep the patent with the largest such count (ties → smallest pub-no.)
   4. Return the first Google-“similar” patent filed the same year
      (if none exists, output NULL).                                    */
WITH candidates AS (  -------------------------------------------------------
    SELECT
        p."publication_number",
        p."filing_date",                         -- yyyymmdd  (NUMBER)
        FLOOR(p."filing_date" / 10000) AS filing_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'
      AND p."application_kind" = 'A'             -- utility
      AND p."grant_date" BETWEEN 20100101 AND 20141231
      AND p."filing_date" BETWEEN 19000101 AND 20991231
),
/* forward citations arriving ≤ 30 days after filing -------------------- */
forward_cites AS (
    SELECT
        c."publication_number"                   AS cited_pub,
        COUNT(*)                                 AS forward_cite_30d
    FROM   candidates c
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" citing
           ON citing."filing_date" BETWEEN c."filing_date"
                                      AND     c."filing_date" + 30
    ,      LATERAL FLATTEN(input => citing."citation") cit
    WHERE  cit.value:"publication_number"::STRING = c."publication_number"
    GROUP  BY c."publication_number"
),
top_candidate AS (  ---------------------------------------------------------
    SELECT
        c."publication_number",
        COALESCE(fc.forward_cite_30d, 0) AS forward_cite_30d,
        c."filing_date",
        c.filing_year
    FROM   candidates c
    LEFT   JOIN forward_cites fc
           ON fc.cited_pub = c."publication_number"
    ORDER  BY forward_cite_30d DESC NULLS LAST,
              c."publication_number"
    LIMIT 1
),
/* unpack similarity list for that patent ------------------------------- */
sim_list AS (
    SELECT
        s.value:"publication_number"::STRING  AS similar_pub,
        s.index::NUMBER                       AS ord
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE."ABS_AND_EMB" a,
           LATERAL FLATTEN(input => a."similar") s
    WHERE  a."publication_number" = (SELECT "publication_number"
                                     FROM top_candidate)
),
same_year_similar AS ( ------------------------------------------------------
    SELECT sl.similar_pub
    FROM   sim_list sl
    JOIN   PATENTS_GOOGLE.PATENTS_GOOGLE."PUBLICATIONS" p
           ON p."publication_number" = sl.similar_pub
    WHERE  p."filing_date" BETWEEN 19000101 AND 20991231
      AND  FLOOR(p."filing_date" / 10000)
           = (SELECT filing_year FROM top_candidate)
    ORDER  BY sl.ord
    LIMIT 1
)
SELECT
    tc."publication_number"      AS "TOP_US_B2_PATENT",
    tc.forward_cite_30d          AS "FWD_CITES_WITHIN_30D",
    sys.similar_pub              AS "MOST_SIMILAR_SAME_YEAR"
FROM   top_candidate tc
LEFT   JOIN same_year_similar sys
       ON 1 = 1;