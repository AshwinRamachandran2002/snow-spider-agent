SELECT
  ROUND(
    COUNT_IF(c."content" ILIKE '%Copyright (c)%')::FLOAT
    / NULLIF(COUNT(*), 0),               -- avoid division by zero
    4                                    -- keep four decimal places
  ) AS "proportion_with_copyright_c"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     AS f
JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES        AS l
  ON f."repo_name" = l."repo_name"
JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS c
  ON f."id" = c."id"
WHERE l."language" NOT ILIKE '%python%'         -- repos that don’t list Python
  AND f."path" ILIKE '%readme.md%';             -- README.md files only