WITH
  duration_stats AS (
    SELECT
      MIN(t."Milliseconds") / 60000.0 AS min_duration_minutes,
      AVG(t."Milliseconds") / 60000.0 AS avg_duration_minutes,
      MAX(t."Milliseconds") / 60000.0 AS max_duration_minutes,
      (MIN(t."Milliseconds") / 60000.0 + AVG(t."Milliseconds") / 60000.0) / 2 AS mid_min_avg,
      (AVG(t."Milliseconds") / 60000.0 + MAX(t."Milliseconds") / 60000.0) / 2 AS mid_avg_max
    FROM MUSIC.MUSIC.TRACK t
  ),
  classified_tracks AS (
    SELECT
      t."TrackId",
      t."Milliseconds" / 60000.0 AS duration_minutes,
      CASE
        WHEN t."Milliseconds" / 60000.0 >= ds.min_duration_minutes AND t."Milliseconds" / 60000.0 < ds.mid_min_avg THEN 'Short'
        WHEN t."Milliseconds" / 60000.0 >= ds.mid_min_avg AND t."Milliseconds" / 60000.0 < ds.mid_avg_max THEN 'Medium'
        WHEN t."Milliseconds" / 60000.0 >= ds.mid_avg_max AND t."Milliseconds" / 60000.0 <= ds.max_duration_minutes THEN 'Long'
        ELSE 'Unclassified'
      END AS category
    FROM MUSIC.MUSIC.TRACK t
    CROSS JOIN duration_stats ds
  ),
  track_revenue AS (
    SELECT
      il."TrackId",
      SUM(il."UnitPrice" * il."Quantity") AS total_revenue
    FROM MUSIC.MUSIC.INVOICELINE il
    GROUP BY il."TrackId"
  )
SELECT
  ct.category AS Category,
  ROUND(MIN(ct.duration_minutes), 4) AS Min_time_minutes,
  ROUND(MAX(ct.duration_minutes), 4) AS Max_time_minutes,
  ROUND(SUM(COALESCE(tr.total_revenue, 0)), 4) AS Total_revenue
FROM classified_tracks ct
LEFT JOIN track_revenue tr ON ct."TrackId" = tr."TrackId"
GROUP BY ct.category
ORDER BY ct.category;