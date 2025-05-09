SELECT
  f.key::STRING  AS "package_name",
  COUNT(*)       AS "frequency"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
     LATERAL FLATTEN(
       INPUT => TRY_PARSE_JSON(c."content"):"require",
       MODE  => 'OBJECT'
     ) AS f
WHERE TRY_PARSE_JSON(c."content"):"require" IS NOT NULL
GROUP BY f.key
ORDER BY "frequency" DESC NULLS LAST;