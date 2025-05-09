SELECT
       f.KEY                  AS "package_name",
       COUNT(*)               AS "freq"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
       LATERAL FLATTEN(
           INPUT => TRY_PARSE_JSON(sc."content"):"require"
       ) AS f
WHERE  TRY_PARSE_JSON(sc."content"):"require" IS NOT NULL
GROUP  BY f.KEY
ORDER  BY "freq" DESC NULLS LAST;