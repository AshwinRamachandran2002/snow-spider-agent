WITH band_event_counts AS (

    /* 1. intersect chr1 cytobands with chr1 allelic CNV segments */
    SELECT
        c."cytoband_name",

        /* classify each overlapping segment */
        CASE WHEN s."copy_number" >= 5 THEN 1 ELSE 0 END AS is_amplification,
        CASE WHEN s."copy_number"  = 3 THEN 1 ELSE 0 END AS is_gain,
        CASE WHEN s."copy_number"  = 1 THEN 1 ELSE 0 END AS is_het_del
    FROM  TCGA_MITELMAN.PROD.CYTOBANDS_HG38                       c
    JOIN  TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23  s
          ON  c."chromosome" = 'chr1'          -- cytoband side
          AND s."chromosome" = 'chr1'          -- segment side
          AND s."start_pos"  <= c."hg38_stop"  -- spatial overlap test
          AND s."end_pos"    >= c."hg38_start"

), band_totals AS (

    /* 2. aggregate counts of each alteration class per cytoband */
    SELECT
        "cytoband_name",
        SUM(is_amplification) AS amp_cnt,
        SUM(is_gain)          AS gain_cnt,
        SUM(is_het_del)       AS het_del_cnt
    FROM  band_event_counts
    GROUP BY "cytoband_name"

), band_ranks AS (

    /* 3. rank cytobands separately by amplifications, gains and het-deletions */
    SELECT
        "cytoband_name",
        RANK() OVER (ORDER BY amp_cnt      DESC NULLS LAST) AS amp_rank,
        RANK() OVER (ORDER BY gain_cnt     DESC NULLS LAST) AS gain_rank,
        RANK() OVER (ORDER BY het_del_cnt  DESC NULLS LAST) AS het_del_rank
    FROM  band_totals
)

-- 4. keep cytobands whose three individual ranks are all within the top 11
SELECT
    "cytoband_name"
FROM  band_ranks
WHERE amp_rank  <= 11
  AND gain_rank <= 11
  AND het_del_rank <= 11
ORDER BY "cytoband_name";