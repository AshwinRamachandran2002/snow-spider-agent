SELECT "package_name", COUNT(*) AS "frequency"
FROM (
  SELECT
    f1."KEY" AS "package_name"
  FROM
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS t,
    LATERAL FLATTEN(input => TRY_PARSE_JSON(t."content")) f,
    LATERAL FLATTEN(input => f."VALUE") f1
  WHERE
    f."KEY" = 'require'
)
GROUP BY "package_name"
ORDER BY "frequency" DESC NULLS LAST;