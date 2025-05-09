WITH all_lines AS (
  SELECT
    ln.value::STRING AS "line_text"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
       LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) ln
)
SELECT
  SUM(CASE WHEN REGEXP_LIKE("line_text", '.[ \t]+$')                           THEN 1 ELSE 0 END) AS "trailing_total",
  SUM(CASE WHEN REGEXP_LIKE("line_text", '^ ')                                 THEN 1 ELSE 0 END) AS "space_total",
  SUM(CASE WHEN NOT REGEXP_LIKE("line_text", '.[ \t]+$')
            AND NOT REGEXP_LIKE("line_text", '^ ')                             THEN 1 ELSE 0 END) AS "other_total"
FROM all_lines;