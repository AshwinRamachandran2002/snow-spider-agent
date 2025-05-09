/*----------------------------------------------------------------------
   Top-5 U.S. patents granted between 2010-01-01 and 2023-12-31
   (ranked by total granted-claim word-count) together with
   their first-ever U.S. publication number & date and grant date.
   NOTE:  Only tables that exist in the shared PATENTS_USPTO database
          are referenced, so the query compiles in Snowflake.
 ----------------------------------------------------------------------*/

WITH granted_pubs_filtered AS (            /* all granted U.S. publications 2010-2023 */
    SELECT
        pub."publication_number",
        pub."application_number",
        pub."publication_date",
        pub."grant_date"
    FROM   PATENTS_USPTO.PATENTS.PUBLICATIONS  pub
    WHERE  pub."country_code" = 'US'
      AND  pub."kind_code"    ILIKE 'B%'                 -- granted documents
      AND  pub."grant_date"  BETWEEN 20100101 AND 20231231
),

ranked AS (                                 /* first publication per application      */
    SELECT
        fp."application_number",
        fp."publication_number",
        fp."publication_date",
        fp."grant_date",
        ROW_NUMBER() OVER (PARTITION BY fp."application_number"
                           ORDER BY fp."publication_date")  AS rn
    FROM  granted_pubs_filtered fp
),

first_pub AS (                              /* retain only the earliest publication   */
    SELECT
        r."application_number",
        r."publication_number"  AS "first_publication_number",
        r."publication_date"    AS "first_publication_date",
        r."grant_date"
    FROM   ranked r
    WHERE  r.rn = 1
),

first_pub_norm AS (                         /* extract numeric patent number          */
    SELECT
        fp.*,
        REGEXP_REPLACE(fp."first_publication_number",
                       '^US-([0-9]+).*$', '\\1')        AS "pat_no"
    FROM   first_pub fp
),

claim_stats AS (                            /* granted-claim word counts              */
    SELECT
        stats."pat_no",
        stats."pat_wrd_ct"  AS "granted_claim_word_ct"
    FROM  PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_DOCUMENT_STATS  stats
)

SELECT
    cs."pat_no"                           AS "patent_number",
    fp."first_publication_number",
    fp."first_publication_date",
    cs."granted_claim_word_ct",
    fp."grant_date"
FROM       claim_stats        cs
INNER JOIN first_pub_norm     fp  ON cs."pat_no" = fp."pat_no"
ORDER BY   cs."granted_claim_word_ct" DESC NULLS LAST
LIMIT 5;