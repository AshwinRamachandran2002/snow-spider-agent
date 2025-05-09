/*  -----------------------------------------------------------
    Chromosomal gain / loss spectrum in breast cancer samples
    (Morphology = '3111') whose primary site is breast
    (Topography = '0401'), based on CytoConverter segments.

    For every cytogenetic band we report, separately,
      • Amplifications  (copy‑number > 1 extra copy)
      • Gains           (1 extra copy)
      • Losses          (1 copy lost)
      • Homo‑del        (2 copies lost)

    Output columns
      chromosome, cytoband_name, hg38_start, hg38_stop,
      event_category, num_cases, frequency_percent (2‑decimals)

    Result set is ordered by chromosome ordinal,
    then band start / stop coordinates (ascending).
    ----------------------------------------------------------- */
WITH
/* 1.  Cohort definition: breast cancer adenocarcinoma cases    */
cohort AS (
  SELECT DISTINCT RefNo, CaseNo
  FROM `mitelman-db.prod.Cytogen`
  WHERE TRIM(Morph) = '3111'           -- breast cancer morphology
    AND TRIM(Topo)  = '0401'           -- adenocarcinoma of breast
),

/* 2.  All CytoConverter calls that belong to the cohort        */
raw_calls AS (
  SELECT cc.RefNo,
         cc.CaseNo,
         cc.Chr            AS chromosome,      -- e.g. 'chr14'
         cc.Start,
         cc.End,
         cc.Type
  FROM   `mitelman-db.prod.CytoConverted` cc
  JOIN   cohort USING (RefNo, CaseNo)
),

/* 3.  Harmonise Type values into the 4 requested categories    */
calls AS (
  SELECT *,
         CASE
           WHEN LOWER(Type) LIKE '%amp%'                      THEN 'Amplification'
           WHEN LOWER(Type) LIKE '%gain%'                     THEN 'Gain'
           WHEN LOWER(Type) LIKE '%hom%'                      THEN 'Homozygous deletion'
           WHEN LOWER(Type) LIKE '%loss%'                     THEN 'Loss'
         END AS event_category
  FROM raw_calls
  WHERE Type IS NOT NULL
),

/* 4.  Intersect every segment with its overlapping cytobands   */
band_overlap AS (
  SELECT DISTINCT
         c.RefNo,
         c.CaseNo,
         b.chromosome,
         b.cytoband_name,
         b.hg38_start,
         b.hg38_stop,
         c.event_category
  FROM   calls            c
  JOIN   `mitelman-db.prod.CytoBands_hg38` b
         ON  b.chromosome         = c.chromosome
         AND c.Start             < b.hg38_stop   -- overlap test
         AND c.End               > b.hg38_start
  WHERE  c.event_category IS NOT NULL
),

/* 5.  Count distinct cases per band & category                 */
band_counts AS (
  SELECT
         chromosome,
         cytoband_name,
         hg38_start,
         hg38_stop,
         event_category,
         COUNT( DISTINCT CONCAT(CAST(RefNo AS STRING), ':', CaseNo) )
           AS num_cases
  FROM   band_overlap
  GROUP  BY chromosome, cytoband_name, hg38_start, hg38_stop, event_category
),

/* 6.  Total number of unique cases in the cohort               */
total_cohort AS (
  SELECT COUNT( DISTINCT CONCAT(CAST(RefNo AS STRING), ':', CaseNo) )
           AS total_cases
  FROM   cohort
)

/* 7.  Final report                                             */
SELECT
  bc.chromosome,
  bc.cytoband_name,
  bc.hg38_start,
  bc.hg38_stop,
  bc.event_category,
  bc.num_cases,
  ROUND( bc.num_cases * 100.0 / tc.total_cases , 2 ) AS frequency_percent
FROM   band_counts  bc
CROSS  JOIN total_cohort tc
ORDER  BY
  /* numeric chromosome order: 1‑22, X=23, Y=24 */
  CASE
    WHEN bc.chromosome = 'chrX' THEN 23
    WHEN bc.chromosome = 'chrY' THEN 24
    ELSE CAST( SUBSTR(bc.chromosome, 4) AS INT64 )
  END,
  bc.hg38_start,
  bc.hg38_stop;