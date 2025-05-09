SELECT DISTINCT
       mr."StudyInstanceUID"
FROM   IDC.IDC_V17."DICOM_PIVOT" AS mr
WHERE  mr."collection_id"        = 'qin_prostate_repeatability'
  AND  mr."Modality"             = 'MR'
  AND  mr."SeriesDescription"   ILIKE '%t2%ax%'
  AND  EXISTS (
        SELECT 1
        FROM   IDC.IDC_V17."SEGMENTATIONS" AS seg
        JOIN   IDC.IDC_V17."DICOM_PIVOT"   AS pv
              ON pv."SeriesInstanceUID" = seg."SeriesInstanceUID"
        WHERE  pv."collection_id"      = 'qin_prostate_repeatability'
          AND  pv."StudyInstanceUID"   = mr."StudyInstanceUID"
          AND  seg."SegmentedPropertyType" ILIKE '%peripheral%zone%'
      )
ORDER BY mr."StudyInstanceUID";