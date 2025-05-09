/*  Top-5 U.S. patents (2010-2023) by total words in granted claims     */
/*  Returns earliest publication in the family, its date, word-count,   */
/*  and the grant date                                                  */

WITH claim_stats AS (          /* granted-claim statistics */
    SELECT
        "pat_no"                                              AS pat_no_raw,
        REGEXP_SUBSTR("pat_no", '[0-9]+')                     AS pat_no_digits,
        TO_NUMBER("pat_wrd_ct")                               AS granted_claim_word_count
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_DOCUMENT_STATS
    WHERE "pat_wrd_ct" IS NOT NULL
      AND REGEXP_SUBSTR("pat_no", '[0-9]+') IS NOT NULL
),

granted_pubs AS (              /* granted U.S. publications 2010-2023 */
    SELECT
        cs.pat_no_raw,
        cs.granted_claim_word_count,
        p."family_id",
        p."publication_date"                AS grant_date
    FROM claim_stats cs
    JOIN (
        SELECT
            "family_id",
            "publication_number",
            "publication_date",
            REGEXP_SUBSTR("publication_number",
                          'US-([0-9]+)', 1, 1, 'e', 1)       AS pat_no_digits
        FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
        WHERE "country_code" = 'US'
          AND "kind_code"  LIKE 'B%'          -- granted
          AND "publication_date" BETWEEN 20100101 AND 20231231
          AND "publication_date" IS NOT NULL
    ) p
      ON p.pat_no_digits = cs.pat_no_digits
),

first_family_pub AS (          /* first publication per family */
    SELECT
        "family_id",
        "publication_number"  AS first_publication_number,
        "publication_date"    AS first_publication_date
    FROM (
        SELECT
            "family_id",
            "publication_number",
            "publication_date",
            ROW_NUMBER() OVER (PARTITION BY "family_id"
                               ORDER BY "publication_date") AS rn
        FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
        WHERE "family_id" IN (SELECT DISTINCT "family_id" FROM granted_pubs)
          AND "publication_date" IS NOT NULL
    )
    WHERE rn = 1
)

SELECT
    gp.pat_no_raw                  AS patent_number,
    fp.first_publication_number,
    fp.first_publication_date,
    gp.granted_claim_word_count,
    gp.grant_date
FROM granted_pubs     gp
JOIN first_family_pub fp  USING ("family_id")
ORDER BY gp.granted_claim_word_count DESC NULLS LAST
LIMIT 5;