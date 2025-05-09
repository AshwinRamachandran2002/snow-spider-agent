SELECT
  r.key::STRING AS "package_name",
  COUNT(*)      AS "frequency"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS t,
     LATERAL FLATTEN(INPUT => PARSE_JSON(t."content"):"require") AS r
WHERE t."sample_path" ILIKE '%composer.json%'
  AND t."binary" = FALSE
GROUP BY "package_name"
ORDER BY "frequency" DESC NULLS LAST, "package_name" ASC;