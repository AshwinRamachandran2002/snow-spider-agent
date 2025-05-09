SELECT f.key AS "package_name", COUNT(*) AS "frequency"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS t,
     LATERAL FLATTEN(input => TRY_PARSE_JSON(t."content")['require']) f
WHERE t."sample_path" = 'composer.json'
  AND t."binary" = FALSE
  AND t."content" IS NOT NULL
  AND f.key IS NOT NULL
GROUP BY f.key
ORDER BY "frequency" DESC NULLS LAST, "package_name" ASC;