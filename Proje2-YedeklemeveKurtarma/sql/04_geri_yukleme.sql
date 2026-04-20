-- ================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 4: Geri Yükleme (Restore)
-- Veritabanı: Chinook
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================

USE master;

-- Sorgu 1: Tam yedeği yeni bir veritabanına geri yükle
-- WITH MOVE: dosyaları farklı konuma taşı
-- REPLACE: hedef veritabanı varsa üzerine yaz
-- Sonuç: 762 sayfa, 0.014 saniyede geri yüklendi (424.944 MB/sn)
RESTORE DATABASE Chinook_Restored
FROM DISK = 'C:\Backup\Chinook_Full.bak'
WITH MOVE 'Chinook' TO 'C:\Backup\Chinook_Restored.mdf',
     MOVE 'Chinook_log' TO 'C:\Backup\Chinook_Restored_log.ldf',
     REPLACE;

-- Sorgu 2: Geri yüklenen veritabanını doğrula
-- Sonuç: Genre sayısı = 25 (tam yedek Jazz Fusion ve Ambient eklenmeden önce alındığı için)
-- Bu, yedeğin tam yedek anındaki durumu doğru yansıttığını kanıtlar
USE Chinook_Restored;

SELECT COUNT(*) AS GenreSayisi FROM Genre;
SELECT * FROM Genre ORDER BY GenreId DESC;
