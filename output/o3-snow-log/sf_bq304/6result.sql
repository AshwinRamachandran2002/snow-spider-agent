WITH tagged AS (
    /* explode the tag string into individual tags */
    SELECT
        q."id",
        q."title",
        q."body",
        q."view_count",
        tag.value          AS tag
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS q,
         LATERAL SPLIT_TO_TABLE(q."tags", '|') tag
    WHERE tag.value IN (
        'android-layout','android-activity','android-intent','android-edittext',
        'android-fragments','android-recyclerview','listview',
        'android-actionbar','google-maps','android-asynctask'
    )
), filtered AS (
    /* keep only rows that contain “how” and none of the trouble-shooting terms */
    SELECT *
    FROM tagged
    WHERE (LOWER("title") LIKE '%how%' OR LOWER("body") LIKE '%how%')
      AND NOT REGEXP_LIKE(LOWER("title"),
            '\\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\\b')
      AND NOT REGEXP_LIKE(LOWER("body"),
            '\\b(fail|problem|error|wrong|fix|bug|issue|solve|trouble)\\b')
), tag_counts AS (
    /* keep only tags that have at least 50 qualifying questions */
    SELECT tag, COUNT(*) AS cnt
    FROM filtered
    GROUP BY tag
    HAVING cnt >= 50
), ranked AS (
    /* rank questions within each tag by view count */
    SELECT
        f.tag,
        f."id",
        f."title",
        f."view_count",
        ROW_NUMBER() OVER (PARTITION BY f.tag
                           ORDER BY f."view_count" DESC NULLS LAST) AS rn
    FROM filtered f
    JOIN tag_counts c
      ON f.tag = c.tag
)
SELECT
    tag,
    "id",
    "title",
    "view_count"
FROM ranked
WHERE rn <= 50         -- top 50 per tag
ORDER BY tag, "view_count" DESC NULLS LAST;