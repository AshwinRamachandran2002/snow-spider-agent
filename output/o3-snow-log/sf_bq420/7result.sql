/*  Top-5 patents that (i) had an early US application publication which
     mentions a §101 rejection with “no allowed claim”, (ii) were later
     granted in the United States (2010-2023), ordered by the total word-
     length of the finally-granted claims.  The query also tries to recover
     the first office-action date from PTAB filings whose document titles
     contain the phrase “Office Action”.                                               */

WITH flagged_pub AS (   --------------------------------------------------------------
    /*  1)  First-in-family US “A*” publication that contains both key phrases  */
    SELECT
        pub."family_id",
        pub."publication_number"                       AS "first_pub_no",
        pub."publication_date"                         AS "first_pub_date"
    FROM (
        SELECT  p.*,
                ROW_NUMBER() OVER (PARTITION BY p."family_id"
                                   ORDER BY p."publication_date")         AS rn
        FROM    PATENTS_USPTO.PATENTS."PUBLICATIONS"  p
        WHERE   p."country_code" = 'US'
          AND   p."kind_code"   ILIKE 'A%'      -- application publications
          AND   LOWER(p."description_localized_html") ILIKE '%section%101%'
          AND   LOWER(p."description_localized_html") ILIKE '%no%allowed%claim%'
    ) pub
    WHERE pub.rn = 1
),

grants AS (          --------------------------------------------------------------
    /*  2)  US grants (kind-code “B*”) inside the same simple family, 2010-23  */
    SELECT
        g."family_id",
        g."publication_number"                         AS "grant_pub_no",
        g."publication_date"                           AS "grant_date",
        SPLIT_PART(g."publication_number", '-', 2)     AS "pat_no"
    FROM  PATENTS_USPTO.PATENTS."PUBLICATIONS" g
    WHERE g."country_code" = 'US'
      AND g."kind_code"    ILIKE 'B%'                 -- granted patents
      AND g."publication_date" BETWEEN 20100101 AND 20231231
),

matched AS (         --------------------------------------------------------------
    /* 3)  Keep only families that satisfy BOTH conditions above               */
    SELECT
        gr."pat_no",
        gr."grant_pub_no",
        gr."grant_date",
        fp."first_pub_no",
        fp."first_pub_date"
    FROM   grants       gr
    JOIN   flagged_pub  fp  ON gr."family_id" = fp."family_id"
),

claim_totals AS (     --------------------------------------------------------------
    /* 4)  Aggregate word–counts of all granted claims                         */
    SELECT
        pcs."pat_no",
        SUM(pcs."word_ct")                           AS "granted_word_len"
    FROM   PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_CLAIMS_STATS"  pcs
    GROUP  BY pcs."pat_no"
),

office_action AS (    --------------------------------------------------------------
    /* 5)  First PTAB filing whose title contains “Office Action” (if any)     */
    SELECT
        t."PatentNumber"                                AS "pat_no",
        MIN( TO_DATE(f.value:"FilingDatetime") )        AS "first_office_action_date"
    FROM PATENTS_USPTO.USPTO_PTAB."TRIALS_201710"  t,
         LATERAL FLATTEN ( INPUT => t."Documents" )  f
    WHERE LOWER( f.value:"Title" ) ILIKE '%office action%'
    GROUP BY t."PatentNumber"
)

-- 6)  Final list – top-5 by granted-claim length -------------------------------
SELECT
    m."pat_no",                       -- granted US patent number
    m."first_pub_no",                 -- first application publication
    m."first_pub_date",
    oa."first_office_action_date",    -- earliest Office-action date (if found)
    ct."granted_word_len",            -- total words across all granted claims
    m."grant_pub_no",                 -- granted publication number
    m."grant_date"
FROM   matched        m
LEFT   JOIN claim_totals   ct  ON ct."pat_no" = m."pat_no"
LEFT   JOIN office_action  oa  ON oa."pat_no" = m."pat_no"
ORDER  BY ct."granted_word_len" DESC NULLS LAST
LIMIT 5;