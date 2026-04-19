-- ================================================
-- PROJE 1: Veritabanı Performans Optimizasyonu ve İzleme
-- Adım 1: Veritabanı Tanıtımı
-- Veritabanı: NYCTaxi_Sample
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE NYCTaxi_Sample;

-- 1. Veritabanındaki tabloları listele
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- 2. Toplam kayıt sayısı
SELECT COUNT(*) AS ToplamKayit FROM nyctaxi_sample;

-- 3. İlk 10 satıra bak (veri yapısını tanımak için)
SELECT TOP 10 * FROM nyctaxi_sample;

-- 4. Sütun yapısı ve veri tipleri
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'nyctaxi_sample';
