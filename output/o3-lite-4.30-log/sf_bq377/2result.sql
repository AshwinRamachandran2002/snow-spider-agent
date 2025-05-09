SELECT
    f.key AS "package_name",
    COUNT(*) AS "frequency"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
     LATERAL FLATTEN(INPUT => PARSE_JSON(sc."content"):"require") f
WHERE sc."sample_path" ILIKE '%composer.json'
  AND TRY_PARSE_JSON(sc."content") IS NOT NULL
GROUP BY f.key
ORDER BY "frequency" DESC NULLS LAST,
         "package_name" ASC;