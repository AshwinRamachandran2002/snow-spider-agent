WITH "lines" AS (
    SELECT
        f.value::STRING AS "line"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
)
SELECT
    /* lines that end with a blank (space or tab) */
    SUM(CASE WHEN "line" RLIKE '.*[ \\t]$'                       THEN 1 ELSE 0 END) AS "trailing_count",
    /* lines that start with a space and are not already counted as trailing */
    SUM(CASE WHEN "line" NOT RLIKE '.*[ \\t]$' AND "line" LIKE ' %' THEN 1 ELSE 0 END) AS "space_count",
    /* all remaining lines */
    SUM(CASE WHEN "line" NOT RLIKE '.*[ \\t]$' AND "line" NOT LIKE ' %' THEN 1 ELSE 0 END) AS "other_count"
FROM "lines";