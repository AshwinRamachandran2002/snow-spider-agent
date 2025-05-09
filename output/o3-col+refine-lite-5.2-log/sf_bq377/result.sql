SELECT
       fl.key::STRING                 AS "package_name",
       COUNT(*)                       AS "frequency"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
       LATERAL FLATTEN(INPUT => TRY_PARSE_JSON(sc."content"):require) fl
WHERE  sc."sample_path" ILIKE '%composer.json'
GROUP  BY fl.key::STRING
ORDER  BY "frequency" DESC NULLS LAST,
          "package_name";