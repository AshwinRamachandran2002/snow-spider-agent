WITH t2_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE LOWER("collection_id") = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" IS NOT NULL
      AND LOWER("SeriesDescription") LIKE '%t2%'
      AND (LOWER("SeriesDescription") LIKE '%ax%' OR LOWER("SeriesDescription") LIKE '%axial%')
),
peripheral_zone_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "StudyInstanceUID" IS NOT NULL
      AND LOWER(TO_VARCHAR("SegmentedPropertyType")) LIKE '%peripheral zone%'
)
SELECT DISTINCT t."StudyInstanceUID"
FROM t2_studies t
JOIN peripheral_zone_studies p
  ON t."StudyInstanceUID" = p."StudyInstanceUID"
ORDER BY t."StudyInstanceUID";