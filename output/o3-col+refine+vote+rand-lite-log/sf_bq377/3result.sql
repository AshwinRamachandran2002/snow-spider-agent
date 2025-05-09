SELECT
  f.key   AS "package_name",
  COUNT(*) AS "occurrences"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
     LATERAL FLATTEN(INPUT => PARSE_JSON(c."content"):"require") f
WHERE c."sample_path" ILIKE '%composer.json%'
GROUP BY f.key
ORDER BY "occurrences" DESC NULLS LAST;