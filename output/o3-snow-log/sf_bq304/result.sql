WITH relevant AS (      -- questions that contain “how” and none of the troubleshooting terms
    SELECT  q."id",
            q."title",
            q."body",
            q."view_count",
            LOWER(q."tags")          AS tags_lc
    FROM    STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS"  q
    WHERE   POSITION('how' IN LOWER(COALESCE(q."title",'') || ' ' || COALESCE(q."body",''))) > 0
      AND  NOT REGEXP_LIKE( LOWER(COALESCE(q."title",'') || ' ' || COALESCE(q."body",'')),
                            '\\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\\b' )
      AND   q."tags" IS NOT NULL
),
exploded AS (           -- explode tag list and keep only the ten android-related tags
    SELECT  r.*,
            TRIM(t.value) AS tag
    FROM    relevant  r,
            LATERAL FLATTEN( INPUT => SPLIT(r.tags_lc, '|') ) t
    WHERE   tag IN ('android-layout','android-activity','android-intent','android-edittext',
                    'android-fragments','android-recyclerview','listview','android-actionbar',
                    'google-maps','android-asynctask')
),
tag_counts AS (         -- keep only tags that have at least 50 qualifying questions
    SELECT  tag, COUNT(*) AS cnt
    FROM    exploded
    GROUP BY tag
    HAVING  cnt >= 50
),
ranked AS (             -- rank questions by view_count within each tag
    SELECT  e.tag,
            e."id",
            e."title",
            e."view_count",
            ROW_NUMBER() OVER (PARTITION BY e.tag
                               ORDER BY e."view_count" DESC NULLS LAST) AS rn
    FROM    exploded  e
    JOIN    tag_counts tc
           ON e.tag = tc.tag
)
SELECT  tag,
        "id",
        "title",
        "view_count"
FROM    ranked
WHERE   rn <= 50               -- top-50 most viewed per tag
ORDER BY tag,
         "view_count" DESC NULLS LAST;