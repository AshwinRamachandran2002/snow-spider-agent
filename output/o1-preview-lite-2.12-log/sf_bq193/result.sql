SELECT
  lr."line",
  COUNT(*) AS "occurrence",
  LISTAGG(DISTINCT lang_flat."language", ', ') WITHIN GROUP (ORDER BY lang_flat."language") AS "languages"
FROM (
  SELECT
    c."sample_repo_name",
    TRIM(line.VALUE::STRING) AS "line"
  FROM
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c,
    LATERAL FLATTEN(input => SPLIT(c."content", '\n')) line
  WHERE
    c."sample_path" = 'README.md'
    AND c."binary" = FALSE
    AND c."content" IS NOT NULL
    AND TRIM(line.VALUE::STRING) != ''
    AND NOT TRIM(line.VALUE::STRING) LIKE '#%'
    AND NOT TRIM(line.VALUE::STRING) LIKE '//%'
) lr
JOIN (
  SELECT
    l."repo_name",
    lang.VALUE:"name"::STRING AS "language"
  FROM
    "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
    LATERAL FLATTEN(input => l."language") lang
) lang_flat
  ON lr."sample_repo_name" = lang_flat."repo_name"
GROUP BY
  lr."line"
ORDER BY
  "occurrence" DESC NULLS LAST, lr."line"
LIMIT 100;