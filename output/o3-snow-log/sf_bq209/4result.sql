/* 1)  Utility patents granted in 2010                                         */
/* 2)  Explode every publication’s “citation” array to                          */
/*     obtain (citing-pub  →  cited-pub) links                                  */
/* 3)  Keep only those links where the cited publication is one of the 2010     */
/*     utility patents and the citing application was filed within ten years    */
/*     after the cited patent’s own filing date                                 */
/* 4)  Count distinct citing application numbers per 2010 utility patent        */
/* 5)  Return the number of 2010 utility patents that have exactly ONE such     */
/*     forward citation                                                         */
WITH patent2010 AS (          -- utility patents granted in calendar-year 2010
    SELECT
        "publication_number",
        "application_number",
        "filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'U'                     -- utility patents
      AND "grant_date" BETWEEN 20100101 AND 20101231   -- granted in 2010
      AND "filing_date" > 0                            -- keep valid dates
),
citation_links AS (          -- explode citations of every publication
    SELECT
        p."publication_number"             AS citing_pub_num,
        p."application_number"             AS citing_app_num,
        p."filing_date"                    AS citing_filing_date,
        c.value:"publication_number"::STRING AS cited_pub_num
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
      AND p."filing_date" > 0
),
forward_cites AS (           -- forward citations within 10-year window
    SELECT
        tgt."publication_number"                       AS target_pub,
        COUNT(DISTINCT cl.citing_app_num)              AS fwd_cite_cnt
    FROM patent2010 tgt
    JOIN citation_links cl
      ON cl.cited_pub_num = tgt."publication_number"
     AND TO_DATE(cl.citing_filing_date::STRING,'YYYYMMDD')
         BETWEEN TO_DATE(tgt."filing_date"::STRING,'YYYYMMDD')
             AND DATEADD(YEAR, 10,
                         TO_DATE(tgt."filing_date"::STRING,'YYYYMMDD'))
    GROUP BY tgt."publication_number"
),
exactly_one AS (             -- keep patents with exactly one forward citation
    SELECT target_pub
    FROM forward_cites
    WHERE fwd_cite_cnt = 1
)
SELECT COUNT(*) AS "NUM_UTILITY_PATENTS_GRANTED_2010_WITH_EXACTLY_ONE_FORWARD_CITATION"
FROM patent2010 p
JOIN exactly_one e
  ON p."publication_number" = e.target_pub;