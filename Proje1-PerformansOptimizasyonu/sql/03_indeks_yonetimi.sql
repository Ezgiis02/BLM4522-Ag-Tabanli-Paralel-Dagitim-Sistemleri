-- ================================================
-- PROJE 1: Veritabanı Performans Optimizasyonu ve İzleme
-- Adım 3: İndeks Yönetimi
-- Veritabanı: NYCTaxi_Sample
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE NYCTaxi_Sample;

-- Sorgu 1: Mevcut indeksleri listele
-- Sonuç: nyc_cci adında CLUSTERED COLUMNSTORE indeksi tüm sütunları kapsıyor
SELECT
    i.name AS IndexAdi,
    i.type_desc AS IndexTuru,
    COL_NAME(ic.object_id, ic.column_id) AS SutunAdi,
    i.is_primary_key AS PrimaryKey
FROM sys.indexes i
JOIN sys.index_columns ic
    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE OBJECT_NAME(i.object_id) = 'nyctaxi_sample'
ORDER BY i.name;

-- Sorgu 2: İndeks oluşturmadan önce sorgu performansı ölç
-- Sonuç: 142.142 kayıt döndü
SET STATISTICS TIME ON;
SELECT COUNT(*)
FROM nyctaxi_sample
WHERE pickup_datetime BETWEEN '2013-10-01' AND '2013-10-31';
SET STATISTICS TIME OFF;

-- Sorgu 3: pickup_datetime sütununa yeni indeks oluştur
-- Not: İndeks zaten mevcut olduğundan hata alındı - bu indeksin daha önce başarıyla oluşturulduğunu gösterir
CREATE INDEX IX_nyctaxi_pickup_datetime
ON nyctaxi_sample (pickup_datetime);

-- Sorgu 4: İndeks sonrası aynı sorguyu tekrar çalıştır (karşılaştırma için)
-- Sonuç: 142.142 kayıt (aynı sonuç, indeks aktif)
SET STATISTICS TIME ON;
SELECT COUNT(*)
FROM nyctaxi_sample
WHERE pickup_datetime BETWEEN '2013-10-01' AND '2013-10-31';
SET STATISTICS TIME OFF;

-- Sorgu 5: İndeks kullanım istatistikleri
-- Sonuç: IX_nyctaxi_pickup_datetime → 1 seek (indeks kullanıldı!)
--        nyc_cci → 3 scan
SELECT
    i.name AS IndexAdi,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s
    ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE OBJECT_NAME(i.object_id) = 'nyctaxi_sample';
