WITH all_lines AS (
    SELECT
        CASE
            /* line ends with one or more spaces or tabs */
            WHEN REGEXP_LIKE(f.VALUE::STRING, '[ \t]+$') THEN 'trailing'
            /* line starts with a single space character */
            WHEN REGEXP_LIKE(f.VALUE::STRING, '^ ')              THEN 'Space'
            /* all other lines */
            ELSE 'Other'
        END                                                         AS line_type
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f
)
SELECT
    line_type,
    COUNT(*) AS occurrences
FROM all_lines
GROUP BY line_type;