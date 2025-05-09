SELECT
  ROUND(
    (
      SELECT COUNT(*)
      FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
      JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
        ON f."id" = c."id"
      WHERE f."path" ILIKE '%readme.md%'
        AND c."content" ILIKE '%Copyright (c)%'
        AND f."repo_name" NOT IN (
          SELECT DISTINCT l."repo_name"
          FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
            LATERAL FLATTEN(input => l."language") lang
          WHERE lang.VALUE::STRING ILIKE '%python%'
        )
    )::FLOAT /
    (
      SELECT COUNT(*)
      FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
      WHERE f."path" ILIKE '%readme.md%'
        AND f."repo_name" NOT IN (
          SELECT DISTINCT l."repo_name"
          FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
            LATERAL FLATTEN(input => l."language") lang
          WHERE lang.VALUE::STRING ILIKE '%python%'
        )
    ),
    4
  ) AS "proportion";