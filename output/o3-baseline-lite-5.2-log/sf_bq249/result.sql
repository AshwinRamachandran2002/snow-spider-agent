WITH "lines" AS (
    /* break every file’s text into individual lines */
    SELECT
        l.value::text AS "line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    , LATERAL FLATTEN(
          input => SPLIT(                 -- split on LF
                     REGEXP_REPLACE("content", '\r', ''),  -- drop CR if present
                     '\n')
      ) l
)
SELECT 'trailing' AS "line_type", COUNT(*) AS "occurrences"
FROM   "lines"
WHERE  REGEXP_LIKE("line", '[ \t]+$')                         -- ends with space or tab
UNION ALL
SELECT 'Space',            COUNT(*)
FROM   "lines"
WHERE  NOT REGEXP_LIKE("line", '[ \t]+$')                     -- not already counted
  AND  REGEXP_LIKE("line", '^ ')                              -- starts with a space
UNION ALL
SELECT 'Other',            COUNT(*)
FROM   "lines"
WHERE  NOT REGEXP_LIKE("line", '[ \t]+$')                     -- not trailing
  AND  NOT REGEXP_LIKE("line", '^ ');                         -- not leading space