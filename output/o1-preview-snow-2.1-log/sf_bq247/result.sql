SELECT p."family_id", f.value:"text"::STRING AS "abstract_localized"
FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
JOIN (
    SELECT "family_id"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "family_id" IS NOT NULL AND "family_id" != '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 6
) top_families ON p."family_id" = top_families."family_id"
CROSS JOIN LATERAL FLATTEN(input => p."abstract_localized") f
WHERE f.value:"text"::STRING IS NOT NULL AND f.value:"text"::STRING != ''
ORDER BY p."family_id", p."publication_number";