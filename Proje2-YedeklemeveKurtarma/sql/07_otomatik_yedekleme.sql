-- ================================================
-- PROJE 2: Veritabanı Yedekleme ve Felaketten Kurtarma
-- Adım 7: Zamanlayıcılarla Otomatik Yedekleme
-- Veritabanı: Chinook
-- Platform: MS SQL Server (LocalDB)
-- Tarih: Nisan 2026
-- ================================================
-- NOT: SQL Server Agent, LocalDB ortamında desteklenmemektedir.
-- Bu script tam SQL Server kurulumunda çalıştırıldığında
-- her gece otomatik yedekleme gerçekleştirir.
-- LocalDB'de İleti 22001 uyarısı beklenen bir davranıştır.
-- ================================================

USE msdb;

-- SQL Server Agent Job oluştur
EXEC sp_add_job
    @job_name = N'Chinook_Otomatik_Yedekleme';

-- Job adımı ekle: Tam yedek komutu
EXEC sp_add_jobstep
    @job_name = N'Chinook_Otomatik_Yedekleme',
    @step_name = N'Tam Yedek Al',
    @command = N'BACKUP DATABASE Chinook
TO DISK = ''C:\Backup\Chinook_Otomatik.bak''
WITH FORMAT, NAME = ''Otomatik Yedek''';

-- Zamanlama tanımla: Her gün gece yarısı
EXEC sp_add_schedule
    @schedule_name = N'Her_Gun_Gece_Yaris',
    @freq_type = 4,        -- Günlük
    @freq_interval = 1,    -- Her 1 günde bir
    @active_start_time = 000000; -- 00:00:00

-- Zamanlamayı job'a bağla
EXEC sp_attach_schedule
    @job_name = N'Chinook_Otomatik_Yedekleme',
    @schedule_name = N'Her_Gun_Gece_Yaris';

-- Sonuç: LocalDB'de İleti 22001 - SQL Server Agent desteklenmiyor
-- Production SQL Server ortamında başarıyla çalışır
