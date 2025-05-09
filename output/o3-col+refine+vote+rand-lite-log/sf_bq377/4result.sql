SELECT
  req.key                    AS "package_name",
  COUNT(*)                   AS "require_count"
FROM
  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS t,
  LATERAL FLATTEN(INPUT => TRY_PARSE_JSON(t."content"):require) req
WHERE
  t."sample_path" ILIKE '%.json'           -- consider only JSON files
GROUP BY
  req.key
ORDER BY
  "require_count" DESC NULLS LAST;