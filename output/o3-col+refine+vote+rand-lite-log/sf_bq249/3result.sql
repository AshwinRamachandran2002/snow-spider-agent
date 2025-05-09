SELECT
        /* lines that end with one or more blanks (spaces or tabs) */
        SUM(CASE WHEN REGEXP_LIKE(f.VALUE::STRING, '[ \t]+$')  THEN 1 ELSE 0 END) AS "trailing",
        /* lines that start with a single blank space character */
        SUM(CASE WHEN REGEXP_LIKE(f.VALUE::STRING, '^ ')       THEN 1 ELSE 0 END) AS "Space",
        /* all other lines */
        SUM(CASE WHEN NOT REGEXP_LIKE(f.VALUE::STRING, '^ ')
                  AND NOT REGEXP_LIKE(f.VALUE::STRING, '[ \t]+$')
                 THEN 1 ELSE 0 END)                            AS "Other"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS t,
       LATERAL FLATTEN(INPUT => SPLIT(t."content", '\n'))      AS f
WHERE  t."binary" = FALSE;