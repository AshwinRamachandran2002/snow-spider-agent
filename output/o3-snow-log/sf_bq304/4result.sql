WITH target_tags(tag) AS (          -- list of tags we care about
    SELECT column1
    FROM VALUES
        ('android-layout'),
        ('android-activity'),
        ('android-intent'),
        ('android-edittext'),
        ('android-fragments'),
        ('android-recyclerview'),
        ('listview'),
        ('android-actionbar'),
        ('google-maps'),
        ('android-asynctask')
),                                                         -- keep only questions that …
filtered AS (                                              -- • have at least one target tag
    SELECT                                                 -- • contain “how” in title or body
        q."id",                                            -- • do NOT contain any trouble-shooting term in title or body
        q."title",
        q."body",
        q."view_count",
        q."tags",
        t.tag
    FROM STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
    JOIN target_tags t
      ON REGEXP_LIKE(q."tags", CONCAT('(^|\\|)', t.tag, '(\\||$)'))
    WHERE (
              LOWER(q."title") LIKE '%how%'
              OR LOWER(q."body")  LIKE '%how%'
          )
      AND NOT (
              REGEXP_LIKE(LOWER(q."title"), '(fail|problem|error|wrong|fix|bug|issue|solve|trouble)')
              OR REGEXP_LIKE(LOWER(q."body"),  '(fail|problem|error|wrong|fix|bug|issue|solve|trouble)')
          )
),                                                         -- keep only tags that have ≥ 50 qualifying questions
tag_counts AS (
    SELECT tag, COUNT(*) AS cnt
    FROM filtered
    GROUP BY tag
    HAVING cnt >= 50
),                                                         -- rank questions by view count inside each remaining tag
ranked AS (
    SELECT
        f.tag,
        f."id",
        f."title",
        f."view_count",
        f."tags",
        ROW_NUMBER() OVER (PARTITION BY f.tag ORDER BY f."view_count" DESC NULLS LAST) AS rn
    FROM filtered f
    JOIN tag_counts c
      ON f.tag = c.tag
)
SELECT                                                      -- top-50 most-viewed questions per tag
    tag,
    "id",
    "title",
    "view_count",
    "tags"
FROM ranked
WHERE rn <= 50
ORDER BY tag, "view_count" DESC NULLS LAST;