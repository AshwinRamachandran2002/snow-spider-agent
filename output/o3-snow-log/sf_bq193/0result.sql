/* all README lines, filtered and aggregated with languages */
SELECT
       ln.line,
       COUNT(DISTINCT ln.repo_name)                                    AS repo_freq,
       ARRAY_TO_STRING(
         ARRAY_SORT(ARRAY_AGG(DISTINCT lg.language_name)),
         ','
       )                                                               AS languages
FROM (
        /* lines extracted from README.md files */
        SELECT
               sf."repo_name"                          AS repo_name,
               TRIM(f.value::STRING)                   AS line
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    sf
        JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
               ON sc."id" = sf."id",
               LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f
        WHERE  sf."path" ILIKE '%README.md'
      ) ln
LEFT JOIN (
        /* explode languages per repository */
        SELECT
               l."repo_name"                           AS repo_name,
               f.key::STRING                           AS language_name
        FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
               LATERAL FLATTEN(INPUT => l."language") f
        WHERE  f.key IS NOT NULL         -- ignore empty language arrays
      ) lg
  ON lg.repo_name = ln.repo_name
WHERE ln.line <> ''               -- non-empty
  AND NOT ln.line ILIKE '#%'      -- exclude markdown comments
  AND NOT ln.line ILIKE '//%'     -- exclude code comments
GROUP BY ln.line
ORDER BY repo_freq DESC NULLS LAST;