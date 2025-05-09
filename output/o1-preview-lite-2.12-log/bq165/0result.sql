WITH cohort_cases AS (
  SELECT DISTINCT cg.`RefNo`, cg.`CaseNo`
  FROM `mitelman-db.prod.Cytogen` cg
  WHERE cg.`Morph` = '3111' OR cg.`Topo` = '0401'
),
sample_band_events AS (
  SELECT
    cc.`RefNo`,
    cc.`CaseNo`,
    cc.`Chr` AS Chromosome,
    cb.`cytoband_name` AS Band_name,
    cb.`hg38_start` AS Band_start,
    cb.`hg38_stop` AS Band_end,
    cc.`Type` AS Event_Type,
    COUNT(*) AS Event_Count
  FROM `mitelman-db.prod.CytoConverted` cc
  JOIN cohort_cases cg
    ON cc.`RefNo` = cg.`RefNo` AND cc.`CaseNo` = cg.`CaseNo`
  JOIN `mitelman-db.prod.CytoBands_hg38` cb
    ON cc.`Chr` = cb.`chromosome`
       AND cc.`Start` >= cb.`hg38_start`
       AND cc.`End` <= cb.`hg38_stop`
  GROUP BY
    cc.`RefNo`,
    cc.`CaseNo`,
    Chromosome,
    Band_name,
    Band_start,
    Band_end,
    cc.`Type`
),
classify_events AS (
  SELECT
    sbe.`RefNo`,
    sbe.`CaseNo`,
    sbe.Chromosome,
    sbe.Band_name,
    sbe.Band_start,
    sbe.Band_end,
    CASE
      WHEN sbe.Event_Type = 'Gain' AND sbe.Event_Count > 1 THEN 'Amplification'
      WHEN sbe.Event_Type = 'Gain' AND sbe.Event_Count = 1 THEN 'Gain'
      WHEN sbe.Event_Type = 'Loss' AND sbe.Event_Count > 1 THEN 'HomozygousDeletion'
      WHEN sbe.Event_Type = 'Loss' AND sbe.Event_Count = 1 THEN 'Loss'
      ELSE NULL
    END AS Classified_Event
  FROM sample_band_events sbe
),
events_per_band AS (
  SELECT
    c.Chromosome,
    c.Band_name,
    c.Band_start,
    c.Band_end,
    COUNT(DISTINCT CASE WHEN c.Classified_Event = 'Amplification' THEN CONCAT(c.`RefNo`,'_', c.`CaseNo`) END) AS Amplifications_number,
    COUNT(DISTINCT CASE WHEN c.Classified_Event = 'Gain' THEN CONCAT(c.`RefNo`,'_', c.`CaseNo`) END) AS Gains_number,
    COUNT(DISTINCT CASE WHEN c.Classified_Event = 'Loss' THEN CONCAT(c.`RefNo`,'_', c.`CaseNo`) END) AS Losses_number,
    COUNT(DISTINCT CASE WHEN c.Classified_Event = 'HomozygousDeletion' THEN CONCAT(c.`RefNo`,'_', c.`CaseNo`) END) AS HomozygousDeletions_number
  FROM classify_events c
  GROUP BY
    c.Chromosome,
    c.Band_name,
    c.Band_start,
    c.Band_end
),
total_cases AS (
  SELECT COUNT(*) AS total_cases FROM cohort_cases
),
frequencies AS (
  SELECT
    epb.Chromosome,
    epb.Band_name,
    epb.Band_start,
    epb.Band_end,
    epb.Amplifications_number,
    ROUND(epb.Amplifications_number / tc.total_cases * 100, 2) AS Amplifications_frequency,
    epb.Gains_number,
    ROUND(epb.Gains_number / tc.total_cases * 100, 2) AS Gains_frequency,
    epb.Losses_number,
    ROUND(epb.Losses_number / tc.total_cases * 100, 2) AS Losses_frequency,
    epb.HomozygousDeletions_number,
    ROUND(epb.HomozygousDeletions_number / tc.total_cases * 100, 2) AS HomozygousDeletions_frequency
  FROM events_per_band epb
  CROSS JOIN total_cases tc
)
SELECT
  Chromosome,
  Band_name,
  Band_start,
  Band_end,
  Amplifications_number,
  Amplifications_frequency,
  Gains_number,
  Gains_frequency,
  Losses_number,
  Losses_frequency,
  HomozygousDeletions_number,
  HomozygousDeletions_frequency
FROM frequencies
ORDER BY
  CASE
    WHEN Chromosome = 'chrX' THEN 23
    WHEN Chromosome = 'chrY' THEN 24
    ELSE CAST(REGEXP_REPLACE(Chromosome, r'chr', '') AS INT64)
  END ASC,
  Band_start ASC;