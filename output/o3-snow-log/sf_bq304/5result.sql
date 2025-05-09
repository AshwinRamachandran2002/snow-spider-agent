WITH filtered AS (
    SELECT
        tag.value::string  AS "tag",
        q."id",
        q."title",
        q."view_count",
        q."body"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q,
         LATERAL FLATTEN(input => SPLIT(LOWER(q."tags"), '|')) tag
    WHERE tag.value::string IN ( 'android-layout'
                               , 'android-activity'
                               , 'android-intent'
                               , 'android-edittext'
                               , 'android-fragments'
                               , 'android-recyclerview'
                               , 'listview'
                               , 'android-actionbar'
                               , 'google-maps'
                               , 'android-asynctask')
      AND ( POSITION('how' IN LOWER(COALESCE(q."title", ''))) > 0
            OR POSITION('how' IN LOWER(COALESCE(q."body", ''))) > 0 )
      AND REGEXP_INSTR(LOWER(COALESCE(q."title", '')),
                       '(fail|problem|error|wrong|fix|bug|issue|solve|trouble)') = 0
      AND REGEXP_INSTR(LOWER(COALESCE(q."body", '')),
                       '(fail|problem|error|wrong|fix|bug|issue|solve|trouble)') = 0
),
ranked AS (
    SELECT
        f.*,
        COUNT(*) OVER (PARTITION BY f."tag")                                             AS tag_total,
        ROW_NUMBER() OVER (PARTITION BY f."tag" ORDER BY f."view_count" DESC NULLS LAST) AS rn
    FROM filtered f
)
SELECT
    "tag",
    "id"           AS question_id,
    "title",
    "view_count"
FROM ranked
WHERE tag_total >= 50
  AND rn <= 50
ORDER BY
    "tag",
    "view_count" DESC NULLS LAST;