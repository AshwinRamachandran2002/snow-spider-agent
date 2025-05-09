-- Calculate band–level frequencies of copy-number abnormalities
-- in breast-cancer (Morph = '3111') AND/OR adenocarcinoma
-- (Topo = '0401') samples.

WITH cohort_cases AS (
  -- 1.  Cohort definition = unique (RefNo, CaseNo)
  SELECT DISTINCT RefNo, CaseNo
  FROM   `mitelman-db.prod.Cytogen`
  WHERE  Morph = '3111'
     OR  Topo  = '0401'
),
n_cases AS (
  -- 2.  Total number of cohort samples (denominator for %)
  SELECT COUNT(*) AS total_cases
  FROM   cohort_cases
),
events AS (
  -- 3.  All CytoConverter segments for the cohort
  SELECT
    cv.RefNo,
    cv.CaseNo,
    cv.Chr,
    cv.Start AS Start_bp,
    cv.End   AS End_bp,
    cv.Type
  FROM `mitelman-db.prod.CytoConverted` AS cv
  JOIN cohort_cases AS cc
    USING (RefNo, CaseNo)
),
band_map AS (
  -- 4.  Overlap every segment with every cytogenetic band
  SELECT
    b.chromosome    AS Chr,
    b.cytoband_name AS Band,
    b.hg38_start,
    b.hg38_stop,
    e.Type
  FROM events AS e
  JOIN `mitelman-db.prod.CytoBands_hg38` AS b
    ON  e.Chr       = b.chromosome
    AND e.Start_bp <= b.hg38_stop
    AND e.End_bp   >= b.hg38_start
),
agg AS (
  -- 5.  Count event categories per band
  SELECT
    Chr,
    Band,
    hg38_start,
    hg38_stop,
    SUM(CASE WHEN Type = 'Amp'                          THEN 1 ELSE 0 END) AS amps,
    SUM(CASE WHEN Type = 'Gain'                         THEN 1 ELSE 0 END) AS gains,
    SUM(CASE WHEN Type = 'Loss'                         THEN 1 ELSE 0 END) AS losses,
    SUM(CASE WHEN LOWER(Type) LIKE '%homdel%'           THEN 1 ELSE 0 END) AS homdels
  FROM band_map
  GROUP BY Chr, Band, hg38_start, hg38_stop
)

-- 6.  Add % and order by chromosome ordinal & genomic position
SELECT
  Chr,
  Band,
  hg38_start,
  hg38_stop,
  amps,
  ROUND(amps   * 100.0 / n.total_cases, 2) AS amps_pct,
  gains,
  ROUND(gains  * 100.0 / n.total_cases, 2) AS gains_pct,
  losses,
  ROUND(losses * 100.0 / n.total_cases, 2) AS losses_pct,
  homdels,
  ROUND(homdels * 100.0 / n.total_cases, 2) AS homdels_pct
FROM agg, n_cases AS n
ORDER BY
  CASE
    WHEN Chr = 'chrX' THEN 23
    WHEN Chr = 'chrY' THEN 24
    ELSE CAST(REGEXP_REPLACE(Chr, r'^chr', '') AS INT64)
  END,
  hg38_start,
  hg38_stop;