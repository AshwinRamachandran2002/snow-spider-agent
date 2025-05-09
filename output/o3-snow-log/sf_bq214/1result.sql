/* -----------------------------------------------------------------------
   1. U.S. utility patents (kind-code B2) granted 2010-2014
   2. Count forward citations that arrive ≤ 30 days after filing
   3. Keep the patent with the largest such count
   4. From Google “similar” list pick the first patent; give priority to
      ones filed in the same year, but return something even if none match
------------------------------------------------------------------------ */
WITH
/* ---- candidate B2 U.S. utility patents (grant 2010-2014, valid filing) -- */
"US_B2" AS (
    SELECT  pub."publication_number",
            pub."filing_date",                                   -- INT YYYYMMDD
            TO_DATE(TO_CHAR(pub."filing_date"), 'YYYYMMDD')      AS "FILING_DT"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pub
    WHERE   pub."country_code" = 'US'
      AND   pub."kind_code"    = 'B2'
      AND   pub."grant_date" BETWEEN 20100101 AND 20141231
      AND   pub."filing_date" IS NOT NULL
      AND   pub."filing_date" > 0
),
/* ------------------------ every patent-citation pair --------------------- */
"ALL_CITATIONS" AS (
    SELECT  citing."publication_number"            AS "CITING_PUB",
            TO_DATE(TO_CHAR(citing."publication_date"), 'YYYYMMDD')
                    AS "CITING_DT",
            cit.value:"publication_number"::STRING AS "CITED_PUB"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  citing,
            LATERAL FLATTEN(INPUT => citing."citation") cit
    WHERE   citing."publication_date" IS NOT NULL
      AND   citing."publication_date" > 0
),
/* ------- forward citations that arrive ≤30 days after filing ------------ */
"FWD30" AS (
    SELECT  up."publication_number"                AS "TARGET_PUB",
            COUNT(DISTINCT ac."CITING_PUB")        AS "FWD_CITE_30D"
    FROM    "US_B2"          up
    LEFT JOIN "ALL_CITATIONS" ac
           ON  ac."CITED_PUB" = up."publication_number"
           AND DATEDIFF('day', up."FILING_DT", ac."CITING_DT") BETWEEN 0 AND 30
    GROUP BY up."publication_number"
),
/* -------------------------- best-scoring patent ------------------------- */
"BEST" AS (
    SELECT  "TARGET_PUB"
    FROM   (
            SELECT  "TARGET_PUB",
                    "FWD_CITE_30D",
                    ROW_NUMBER() OVER (ORDER BY "FWD_CITE_30D" DESC NULLS LAST,
                                               "TARGET_PUB") AS rn
            FROM    "FWD30"
           )
    WHERE   rn = 1
),
/* ---------------- information on that best patent ---------------------- */
"BEST_INFO" AS (
    SELECT  p."publication_number"                 AS "TOP_PUB",
            p."filing_date",
            FLOOR(p."filing_date" / 10000)         AS "FILING_YEAR"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN    "BEST" b
          ON p."publication_number" = b."TARGET_PUB"
),
/* ------------- Google-provided list of similar patents ------------------ */
"SIMILAR_LIST" AS (
    SELECT  sim.value:"publication_number"::STRING AS "SIM_PUB",
            sim."INDEX"                            AS "SIM_RANK"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
    JOIN    "BEST" b
          ON ae."publication_number" = b."TARGET_PUB",
            LATERAL FLATTEN(INPUT => ae."similar") sim
),
/* -- choose first similar patent, preferring same filing year ------------ */
"MOST_SIMILAR" AS (
    SELECT  sl."SIM_PUB"
    FROM    "SIMILAR_LIST" sl
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
              ON p."publication_number" = sl."SIM_PUB"
    JOIN    "BEST_INFO" bi
              ON 1 = 1
    QUALIFY ROW_NUMBER() OVER (
              ORDER BY
                  CASE
                       WHEN FLOOR(p."filing_date" / 10000) = bi."FILING_YEAR"
                       THEN 0 ELSE 1 END,
                  sl."SIM_RANK" ASC NULLS LAST
            ) = 1
)
/* ------------------------------ final output ---------------------------- */
SELECT  bi."TOP_PUB"  AS "TOP_PATENT",
        bi."FILING_YEAR",
        ms."SIM_PUB"  AS "MOST_SIMILAR_PATENT_SAME_YEAR"
FROM    "BEST_INFO"  bi
LEFT JOIN "MOST_SIMILAR" ms
       ON 1 = 1;