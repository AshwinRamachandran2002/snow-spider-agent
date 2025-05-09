WITH independent_claim_stats AS (
    /* Independent‑claim statistics from both yearly tables */
    SELECT  "appl_id"   AS APPLICATION_NUMBER,
            "claim_no"  AS CLAIM_NUMBER,
            TO_NUMBER("word_ct") AS WORD_COUNT,
            "pat_no"    AS PATENT_NUMBER
    FROM    PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    WHERE   "ind_flg" = '1'

    UNION ALL
    
    SELECT  "appl_id"   AS APPLICATION_NUMBER,
            "claim_no"  AS CLAIM_NUMBER,
            TO_NUMBER("word_ct") AS WORD_COUNT,
            "pat_no"    AS PATENT_NUMBER
    FROM    PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS_2014
    WHERE   "ind_flg" = '1'
),

/* Map granted patent numbers to their publication numbers */
publication_map AS (
    SELECT DISTINCT
           "pat_no"            AS PATENT_NUMBER,
           "publication_number" AS PUBLICATION_NUMBER
    FROM   PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH
    WHERE  "pat_no" IS NOT NULL
      AND  "pat_no" <> ''
),

claims_with_pubs AS (
    SELECT   ics.APPLICATION_NUMBER,
             ics.CLAIM_NUMBER,
             ics.WORD_COUNT,
             pm.PUBLICATION_NUMBER
    FROM     independent_claim_stats  AS ics
    JOIN     publication_map          AS pm
           ON ics.PATENT_NUMBER = pm.PATENT_NUMBER
),

/* Earliest publication date per application */
earliest_app_publication AS (
    SELECT   p."application_number_formatted"      AS APPLICATION_NUMBER,
             MIN(p."publication_date")             AS EARLIEST_PUB_DATE
    FROM     PATENTS_USPTO.PATENTS.PUBLICATIONS  p
    WHERE    p."application_number_formatted" IS NOT NULL
    GROUP BY p."application_number_formatted"
),

/* Publication numbers that correspond to that earliest date */
earliest_publication_numbers AS (
    SELECT   p."application_number_formatted"      AS APPLICATION_NUMBER,
             p."publication_number"                AS PUBLICATION_NUMBER
    FROM     PATENTS_USPTO.PATENTS.PUBLICATIONS  p
    JOIN     earliest_app_publication            ep
           ON p."application_number_formatted" = ep.APPLICATION_NUMBER
          AND p."publication_date"              = ep.EARLIEST_PUB_DATE
)

/* Final selection */
SELECT   cwp.PUBLICATION_NUMBER     AS "publication_number",
         cwp.APPLICATION_NUMBER     AS "application_number",
         cwp.CLAIM_NUMBER           AS "claim_number",
         cwp.WORD_COUNT             AS "word_count"
FROM     claims_with_pubs            AS cwp
JOIN     earliest_publication_numbers AS epn
       ON cwp.PUBLICATION_NUMBER = epn.PUBLICATION_NUMBER
ORDER BY cwp.WORD_COUNT DESC NULLS LAST,
         cwp.PUBLICATION_NUMBER,
         cwp.CLAIM_NUMBER
LIMIT 100;