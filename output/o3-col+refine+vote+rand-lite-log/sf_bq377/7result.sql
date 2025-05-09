SELECT
  f.key                                   AS "PACKAGE_NAME",
  COUNT(*)                                AS "FREQUENCY"
FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" AS c,
     LATERAL FLATTEN(
       input => TRY_PARSE_JSON(c."content"):"require"
     ) AS f
WHERE c."sample_path" ILIKE '%composer.json'
GROUP BY f.key
ORDER BY "FREQUENCY" DESC NULLS LAST;