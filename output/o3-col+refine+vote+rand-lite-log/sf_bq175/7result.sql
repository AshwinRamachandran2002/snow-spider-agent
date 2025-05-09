/*  Identify cytoband names on chromosome 1 whose
    (1) amplification frequency (copy_number ≥ 4),
    (2) gain frequency (copy_number = 3) and
    (3) heterozygous-deletion frequency (copy_number = 1)
    each rank within the top 11 in the TCGA-KIRC allelic-segment data. */

WITH
-- Chromosome-1 allelic segments (TCGA-KIRC study is the only kidney data in this table)
chr1_segs AS (
    SELECT *
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "chromosome" = 'chr1'
),

-- Map every segment to every cytoband it overlaps
seg2band AS (
    SELECT
        b."cytoband_name",
        s."copy_number"
    FROM chr1_segs s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38" b
      ON  b."chromosome" = s."chromosome"
      AND LEAST(s."end_pos",  b."hg38_stop") 
        > GREATEST(s."start_pos", b."hg38_start")     -- overlap test
),

-- Rank cytobands by amplification counts (copy_number ≥ 4)
amp AS (
    SELECT
        "cytoband_name",
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS "amp_rank"
    FROM seg2band
    WHERE "copy_number" >= 4
    GROUP BY "cytoband_name"
),

-- Rank cytobands by gain counts (copy_number = 3)
gain AS (
    SELECT
        "cytoband_name",
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS "gain_rank"
    FROM seg2band
    WHERE "copy_number" = 3
    GROUP BY "cytoband_name"
),

-- Rank cytobands by heterozygous-deletion counts (copy_number = 1)
het AS (
    SELECT
        "cytoband_name",
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS "het_rank"
    FROM seg2band
    WHERE "copy_number" = 1
    GROUP BY "cytoband_name"
)

-- Select cytobands whose rank ≤ 11 in all three categories
SELECT a."cytoband_name"
FROM   amp  a
JOIN   gain g ON g."cytoband_name" = a."cytoband_name"
JOIN   het  h ON h."cytoband_name" = a."cytoband_name"
WHERE  a."amp_rank"  <= 11
  AND  g."gain_rank" <= 11
  AND  h."het_rank"  <= 11
ORDER BY a."cytoband_name";