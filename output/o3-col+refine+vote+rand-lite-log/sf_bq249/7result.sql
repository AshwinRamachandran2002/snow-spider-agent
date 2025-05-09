WITH line_stats AS (
  SELECT
    /* total number of lines in every file */
    SUM(REGEXP_COUNT("content", '\\n') + 1)                     AS total_lines,

    /* lines that start with a space character (“Space” category) */
    SUM(REGEXP_COUNT("content", '^ ',       1, 'm'))            AS space_lines,

    /* lines that end with a space or tab (“trailing” category)  */
    SUM(REGEXP_COUNT("content", '[ \\t]+$', 1, 'm'))            AS trailing_lines
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
)

SELECT 'trailing' AS line_type, trailing_lines                                             AS occurrences FROM line_stats
UNION ALL
SELECT 'Space'    AS line_type, space_lines                                                AS occurrences FROM line_stats
UNION ALL
SELECT 'Other'    AS line_type, total_lines - space_lines - trailing_lines                 AS occurrences FROM line_stats;