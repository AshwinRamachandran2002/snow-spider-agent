WITH top_families AS (
    SELECT
        "family_id"
    FROM
        PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE
        "family_id" IS NOT NULL
        AND "family_id" <> '-1'
    GROUP BY
        "family_id"
    ORDER BY
        COUNT(*) DESC NULLS LAST
    LIMIT 6
),
pubs_in_families AS (
    SELECT
        p."family_id",
        p."publication_number"
    FROM
        PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
        JOIN top_families tf
            ON p."family_id" = tf."family_id"
)
SELECT DISTINCT
    pf."family_id",
    ae."abstract"
FROM
    pubs_in_families pf
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
        ON ae."publication_number" = pf."publication_number"
WHERE
    ae."abstract" IS NOT NULL
    AND LENGTH(TRIM(ae."abstract")) > 0
ORDER BY
    pf."family_id",
    ae."abstract";