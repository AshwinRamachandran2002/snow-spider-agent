WITH "top_families" AS (
    SELECT "family_id"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS"
    WHERE "family_id" <> '-1'
    GROUP BY "family_id"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 6
)
SELECT p."family_id",
       al.value:"text"::STRING AS "abstract_localized"
FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS" p,
     LATERAL FLATTEN(input => p."abstract_localized") al
WHERE p."family_id" IN (SELECT "family_id" FROM "top_families")
  AND al.value:"text" IS NOT NULL
  AND al.value:"text"::STRING <> ''