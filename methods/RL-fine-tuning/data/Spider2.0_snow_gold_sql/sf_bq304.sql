WITH unnest_tags AS (
  SELECT
    "id",
    "title",
    "view_count",
    LOWER(tag.value) AS tag
  FROM "STACKOVERFLOW"."STACKOVERFLOW"."STACKOVERFLOW_POSTS",
    LATERAL FLATTEN(input => SPLIT(REGEXP_REPLACE(REPLACE("tags", '><', ','), '^<|>$', ''), ',')) AS tag
  WHERE "post_type_id" = 1
    AND "title" ILIKE '%how%'
    AND "title" NOT ILIKE '%fail%'
    AND "title" NOT ILIKE '%problem%'
    AND "title" NOT ILIKE '%error%'
    AND "title" NOT ILIKE '%wrong%'
    AND "title" NOT ILIKE '%fix%'
    AND "title" NOT ILIKE '%bug%'
    AND "title" NOT ILIKE '%issue%'
    AND "title" NOT ILIKE '%solve%'
    AND "title" NOT ILIKE '%trouble%'
)
SELECT
  tag AS "Tag",
  "id" AS "Question_ID",
  "title" AS "Title",
  "view_count" AS "View_Count"
FROM (
  SELECT
    tag,
    "id",
    "title",
    "view_count",
    ROW_NUMBER() OVER (PARTITION BY tag ORDER BY "view_count" DESC NULLS LAST) AS rn
  FROM unnest_tags
  WHERE tag IN (
    'android-layout', 'android-activity', 'android-intent', 'android-edittext',
    'android-fragments', 'android-recyclerview', 'listview', 'android-actionbar',
    'google-maps', 'android-asynctask'
  )
)
WHERE rn <= 50
ORDER BY "Tag", "View_Count" DESC NULLS LAST;