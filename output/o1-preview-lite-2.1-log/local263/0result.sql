SELECT stats."status", stats."L1_model", stats."count"
FROM (
  SELECT status_table."status", m."L1_model", COUNT(*) AS "count"
  FROM (
    SELECT s."name", s."version",
      CASE
        WHEN n."max_non_stack_score" < s."test_score" THEN 'strong'
        WHEN n."max_non_stack_score" = s."test_score" THEN 'soft'
      END AS "status"
    FROM (
      SELECT "name", "version", "test_score"
      FROM "model_score"
      WHERE "model" = 'Stack'
    ) AS s
    JOIN (
      SELECT "name", "version", MAX("test_score") AS "max_non_stack_score"
      FROM "model_score"
      WHERE "model" <> 'Stack'
      GROUP BY "name", "version"
    ) AS n
    ON s."name" = n."name" AND s."version" = n."version"
  ) AS status_table
  JOIN "model" AS m
  ON status_table."name" = m."name" AND status_table."version" = m."version"
  GROUP BY status_table."status", m."L1_model"
) AS stats
WHERE (stats."status", stats."count") IN (
  SELECT "status", MAX("count")
  FROM (
    SELECT status_table."status", m."L1_model", COUNT(*) AS "count"
    FROM (
      SELECT s."name", s."version",
        CASE
          WHEN n."max_non_stack_score" < s."test_score" THEN 'strong'
          WHEN n."max_non_stack_score" = s."test_score" THEN 'soft'
        END AS "status"
      FROM (
        SELECT "name", "version", "test_score"
        FROM "model_score"
        WHERE "model" = 'Stack'
      ) AS s
      JOIN (
        SELECT "name", "version", MAX("test_score") AS "max_non_stack_score"
        FROM "model_score"
        WHERE "model" <> 'Stack'
        GROUP BY "name", "version"
      ) AS n
      ON s."name" = n."name" AND s."version" = n."version"
    ) AS status_table
    JOIN "model" AS m
    ON status_table."name" = m."name" AND status_table."version" = m."version"
    GROUP BY status_table."status", m."L1_model"
  )
  GROUP BY "status"
);