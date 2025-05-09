SELECT
  p."family_id",
  CASE 
    WHEN IS_ARRAY(a.value:"text") THEN ARRAY_TO_STRING(a.value:"text", ', ')
    ELSE a.value:"text"::STRING
  END AS "abstract_localized"
FROM
  PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
  , LATERAL FLATTEN(input => p."abstract_localized") a
WHERE
  p."family_id" IN (
    SELECT
      "family_id"
    FROM
      PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE
      "family_id" IS NOT NULL AND "family_id" <> -1
    GROUP BY
      "family_id"
    ORDER BY
      COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 6
  )
  AND a.value:"text" IS NOT NULL AND a.value:"text" <> ''
ORDER BY
  p."family_id";