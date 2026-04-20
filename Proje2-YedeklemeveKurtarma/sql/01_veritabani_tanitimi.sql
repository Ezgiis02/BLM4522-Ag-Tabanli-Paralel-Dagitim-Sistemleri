-- ================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 1: Veritabanı Tanıtımı
-- Veritabanı: Chinook
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE Chinook;

-- Sorgu 1: Veritabanındaki tabloları listele
-- Sonuç: 11 tablo (Album, Artist, Customer, Employee, Genre,
--         Invoice, InvoiceLine, MediaType, Playlist, PlaylistTrack, Track)
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- Sorgu 2: Her tablodaki kayıt sayıları
-- Sonuç: Artist:275, Album:347, Track:3503, Customer:59,
--         Invoice:412, Employee:8, Genre:25, Playlist:18
SELECT 'Artist' AS Tablo, COUNT(*) AS KayitSayisi FROM Artist UNION ALL
SELECT 'Album', COUNT(*) FROM Album UNION ALL
SELECT 'Track', COUNT(*) FROM Track UNION ALL
SELECT 'Customer', COUNT(*) FROM Customer UNION ALL
SELECT 'Invoice', COUNT(*) FROM Invoice UNION ALL
SELECT 'Employee', COUNT(*) FROM Employee UNION ALL
SELECT 'Genre', COUNT(*) FROM Genre UNION ALL
SELECT 'Playlist', COUNT(*) FROM Playlist;

-- Sorgu 3: Temel tabloların sütun yapısı ve veri tipleri
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Artist','Album','Track','Customer','Invoice')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Sorgu 4: Örnek veri - Track tablosu ilk 10 kayıt
SELECT TOP 10 * FROM Track;
