SELECT
    SUM(CASE WHEN REGEXP_LIKE("line", '[ \t]$') THEN 1 ELSE 0 END)                           AS "trailing_total",
    SUM(CASE WHEN REGEXP_LIKE("line", '^ ')     THEN 1 ELSE 0 END)                           AS "space_total",
    SUM(CASE WHEN NOT REGEXP_LIKE("line", '[ \t]$')
              AND NOT REGEXP_LIKE("line", '^ ') THEN 1 ELSE 0 END)                           AS "other_total"
FROM (
    SELECT
        f.value::STRING AS "line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) f
) AS all_lines;