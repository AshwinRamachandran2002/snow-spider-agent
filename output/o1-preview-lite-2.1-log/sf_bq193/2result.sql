SELECT
  lines.line AS "Line",
  COUNT(*) AS "Frequency",
  LISTAGG(DISTINCT langs.language_name, ', ') WITHIN GROUP (ORDER BY langs.language_name) AS "Languages"
FROM
  (
    SELECT
      sf."repo_name",
      TRIM(t.value::STRING) AS line
    FROM
      GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES sf
    JOIN
      GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
      ON sf."id" = sc."id",
    LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) t
    WHERE
      sf."path" ILIKE '%readme.md'
      AND sc."binary" = FALSE
      AND t.value IS NOT NULL
      AND TRIM(t.value::STRING) != ''
      AND TRIM(t.value::STRING) NOT ILIKE '#%'
      AND TRIM(t.value::STRING) NOT ILIKE '//%'
  ) AS lines
LEFT JOIN
  (
    SELECT
      l."repo_name",
      k.value:"name"::STRING AS language_name
    FROM
      GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
      LATERAL FLATTEN(input => l."language") k
    WHERE
      k.value:"name" IS NOT NULL
  ) AS langs
  ON lines."repo_name" = langs."repo_name"
GROUP BY
  lines.line
ORDER BY
  "Frequency" DESC NULLS LAST
LIMIT 100;