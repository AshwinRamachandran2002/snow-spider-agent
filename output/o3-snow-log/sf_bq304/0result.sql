WITH tags_list AS (               -- 1. tags we care about
    SELECT column1 AS tag_name
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
),

/* 2. questions that
      • contain the tag
      • contain “how” in title or body
      • do NOT contain any troubleshooting words in title or body        */
filtered AS (
    SELECT
        tl.tag_name,
        pq."id",
        pq."title",
        pq."body",
        pq."view_count",
        pq."creation_date"
    FROM tags_list tl
    JOIN STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS pq
          /* precise tag-match against the |-delimited tag field */
          ON   pq."tags" = tl.tag_name
           OR  pq."tags" ILIKE tl.tag_name || '|%'          -- tag is first
           OR  pq."tags" ILIKE '%|' || tl.tag_name || '|%'  -- tag is middle
           OR  pq."tags" ILIKE '%|' || tl.tag_name          -- tag is last
    WHERE (pq."title" ILIKE '%how%' OR pq."body" ILIKE '%how%')
      AND NOT (pq."title" ILIKE '%fail%'      OR pq."body" ILIKE '%fail%')
      AND NOT (pq."title" ILIKE '%problem%'   OR pq."body" ILIKE '%problem%')
      AND NOT (pq."title" ILIKE '%error%'     OR pq."body" ILIKE '%error%')
      AND NOT (pq."title" ILIKE '%wrong%'     OR pq."body" ILIKE '%wrong%')
      AND NOT (pq."title" ILIKE '%fix%'       OR pq."body" ILIKE '%fix%')
      AND NOT (pq."title" ILIKE '%bug%'       OR pq."body" ILIKE '%bug%')
      AND NOT (pq."title" ILIKE '%issue%'     OR pq."body" ILIKE '%issue%')
      AND NOT (pq."title" ILIKE '%solve%'     OR pq."body" ILIKE '%solve%')
      AND NOT (pq."title" ILIKE '%trouble%'   OR pq."body" ILIKE '%trouble%')
),

/* 3. keep only tags having at least 50 qualifying questions */
qualified_tags AS (
    SELECT tag_name
    FROM filtered
    GROUP BY tag_name
    HAVING COUNT(*) >= 50
),

/* 4. rank questions per tag by view_count */
ranked AS (
    SELECT
        f.tag_name,
        f."id"           AS question_id,
        f."title",
        f."view_count",
        f."creation_date",
        ROW_NUMBER() OVER (PARTITION BY f.tag_name
                           ORDER BY f."view_count" DESC NULLS LAST) AS rn
    FROM filtered f
    JOIN qualified_tags q
      ON f.tag_name = q.tag_name
)

/* 5. return top-50 most viewed per qualifying tag */
SELECT
    tag_name,
    question_id,
    "title",
    "view_count",
    "creation_date"
FROM ranked
WHERE rn <= 50
ORDER BY tag_name, "view_count" DESC NULLS LAST;