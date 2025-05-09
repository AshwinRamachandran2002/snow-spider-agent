WITH cohort_cases AS (   -- breast cancer (morph = 3111) or adenocarcinoma (topo = 0401)
  SELECT DISTINCT RefNo, CaseNo
  FROM `mitelman-db.prod.Cytogen`
  WHERE Morph = '3111'
     OR Topo  = '0401'
),
total_cases AS (         -- number of independent cases in the cohort
  SELECT COUNT(*) AS n_cases
  FROM cohort_cases
),
events AS (              -- CytoConverter segments that belong to the cohort
  SELECT cv.RefNo,
         cv.CaseNo,
         cv.Type,
         cv.Chr        AS chromosome,
         cv.Start,
         cv.End
  FROM `mitelman-db.prod.CytoConverted` cv
  JOIN cohort_cases cc
    ON cv.RefNo = cc.RefNo
   AND cv.CaseNo = cc.CaseNo
),
band_overlap AS (        -- overlap each segment with hg38 cytobands
  SELECT *
  FROM (
    SELECT
      e.RefNo,
      e.CaseNo,
      CASE
        WHEN LOWER(e.Type) LIKE '%amp%'                               THEN 'Amplification'
        WHEN LOWER(e.Type) LIKE '%gain%'                              THEN 'Gain'
        WHEN LOWER(e.Type) LIKE '%homo%'                              THEN 'Homozygous Deletion'
        WHEN LOWER(e.Type) LIKE '%loss%' OR LOWER(e.Type) LIKE '%del%' THEN 'Loss'
        ELSE NULL
      END                                            AS event_category,
      b.chromosome,
      b.cytoband_name,
      b.hg38_start,
      b.hg38_stop
    FROM events e
    JOIN `mitelman-db.prod.CytoBands_hg38` b
      ON e.chromosome = b.chromosome             -- same chromosome
     AND e.Start  < b.hg38_stop                  -- intervals overlap
     AND e.End    > b.hg38_start
  )
  WHERE event_category IS NOT NULL               -- keep only mapped categories
),
band_case_once AS (       -- one row per band/case/category
  SELECT DISTINCT
    RefNo,
    CaseNo,
    chromosome,
    cytoband_name,
    hg38_start,
    hg38_stop,
    event_category
  FROM band_overlap
),
band_counts AS (          -- count cases per band/category
  SELECT
    chromosome,
    cytoband_name,
    hg38_start,
    hg38_stop,
    SUM(CASE WHEN event_category = 'Amplification'       THEN 1 ELSE 0 END) AS amplification_cases,
    SUM(CASE WHEN event_category = 'Gain'               THEN 1 ELSE 0 END) AS gain_cases,
    SUM(CASE WHEN event_category = 'Loss'               THEN 1 ELSE 0 END) AS loss_cases,
    SUM(CASE WHEN event_category = 'Homozygous Deletion' THEN 1 ELSE 0 END) AS homdel_cases
  FROM band_case_once
  GROUP BY chromosome, cytoband_name, hg38_start, hg38_stop
),
final AS (                -- add frequencies and chromosome order
  SELECT
    chromosome,
    cytoband_name AS cytoband,
    hg38_start,
    hg38_stop,
    amplification_cases,
    ROUND(100.0 * amplification_cases / (SELECT n_cases FROM total_cases), 2) AS amplification_freq_pct,
    gain_cases,
    ROUND(100.0 * gain_cases / (SELECT n_cases FROM total_cases), 2)          AS gain_freq_pct,
    loss_cases,
    ROUND(100.0 * loss_cases / (SELECT n_cases FROM total_cases), 2)          AS loss_freq_pct,
    homdel_cases,
    ROUND(100.0 * homdel_cases / (SELECT n_cases FROM total_cases), 2)        AS homdel_freq_pct,
    CASE
      WHEN chromosome = 'chrX' THEN 23
      WHEN chromosome = 'chrY' THEN 24
      ELSE CAST(REPLACE(chromosome,'chr','') AS INT64)
    END AS chr_order
  FROM band_counts
)
SELECT
  chromosome,
  cytoband,
  hg38_start,
  hg38_stop,
  amplification_cases,
  amplification_freq_pct,
  gain_cases,
  gain_freq_pct,
  loss_cases,
  loss_freq_pct,
  homdel_cases,
  homdel_freq_pct
FROM final
ORDER BY chr_order, hg38_start, hg38_stop;