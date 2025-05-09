/*  Return 5 largest‑claim U.S. patents granted 2010‑‑2023,
    together with their first publication information
    (PAIR office‑action data not available in current catalog,
     so “first_office_action_date” is reported as NULL).                    */

WITH us_grants AS (                 -- U.S. grants 2010‑01‑01 … 2023‑12‑31
    SELECT
        "publication_number",
        "application_number",
        "grant_date",
        REGEXP_REPLACE("publication_number", '^US-|-[A-Za-z0-9]+$', '') AS "pat_no"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code" ILIKE 'B%'               -- granted documents (B1, B2 …)
      AND "grant_date" BETWEEN 20100101 AND 20231231
),

/*  earliest (first) U.S. publication for each application                 */
first_pub AS (
    SELECT
        p."application_number",
        p."publication_number" AS "first_publication_number",
        p."publication_date"   AS "first_publication_date"
    FROM (
        SELECT
            p.*,
            ROW_NUMBER() OVER (PARTITION BY p."application_number"
                               ORDER BY p."publication_date",
                                        p."publication_number") AS rn
        FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
        WHERE p."country_code" = 'US'
    ) p
    WHERE p.rn = 1
),

/*  total word‑count of all granted claims                                 */
claim_stats AS (
    SELECT
        "pat_no",
        TRY_CAST("pat_wrd_ct" AS NUMBER) AS "claim_word_count"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_DOCUMENT_STATS
)

SELECT
    g."publication_number"        AS "granted_publication_number",
    fp."first_publication_number" AS "first_publication_number",
    fp."first_publication_date"   AS "first_publication_date",
    cs."claim_word_count"         AS "granted_claim_word_count",
    g."grant_date"                AS "grant_date",
    NULL                          AS "first_office_action_date"   -- PAIR data unavailable
FROM       us_grants  g
JOIN       claim_stats cs ON g."pat_no"             = cs."pat_no"
JOIN       first_pub   fp ON g."application_number" = fp."application_number"
ORDER BY   cs."claim_word_count" DESC NULLS LAST,
           g."grant_date" ASC
LIMIT 5;